#include <stdio.h>
#include <string.h>
#include <lwip/err.h>
#include <lwip/udp.h>
#include "xaxidma.h"
#include "xil_cache.h"
#include "xparameters.h"

#if defined (__arm__) || defined (__aarch64__) || defined(__MICROBLAZE__)
#include "xil_printf.h"
#endif

#define DMA_DEV_ID          1
#define MANUAL_DMA_BASEADDR 0x41E10000
#define RX_BUFFER_BASE_ADDR 0x85000000

// FIXED: Expanded to 7 words * 4 bytes/word = 28 bytes total frame length
#define PACKET_BYTE_SIZE    29

#pragma pack(push, 1)
typedef struct {
    uint8_t Pa_LSB;      uint8_t Pa_MSB;      uint8_t Pb_LSB;      uint8_t Pb_MSB;
    uint8_t byte12;      uint8_t byte13;      uint8_t ch9_byte12;  uint8_t ch9_byte13;
    uint8_t ch0_otrm01;  uint8_t ch0_otrm23;  uint8_t ch0_otrm45;  uint8_t ch0_otrm67;
    uint8_t ch0_otrm89;  uint8_t ch0_otrm1011;uint8_t ch0_otrm1213;uint8_t ch0_otrm1415;
    uint8_t ch9_otrm01;  uint8_t ch9_otrm23;  uint8_t ch9_otrm45;  uint8_t ch9_otrm67;
    uint8_t ch9_otrm89;  uint8_t ch9_otrm1011;uint8_t ch9_otrm1213;uint8_t ch9_otrm1415;

    // FIXED: Appended real-time status tracking parameters variables
    uint8_t rfif_fwd_pwr_sts;
    uint8_t rfif_slb_out_sts;
    uint8_t rfif_temp_sts;
    uint8_t rfif_path_cal_sts;
    uint8_t rfif_amp_cal_sts;
} QtTelemetryPkt;
#pragma pack(pop)

static struct udp_pcb *app_pcb = NULL;
static ip_addr_t gui_ipaddr;
static XAxiDma AxiDma;
static int dma_initialized = 0;
static int dma_transfer_submitted = 0;

int init_dma_engine() {
    XAxiDma_Config Cfg;
    int Status, Timeout = 10000;
    xil_printf("[INIT] Manually configuring Custom DMA Core at 0x%08X...\r\n", MANUAL_DMA_BASEADDR);

    Cfg.DeviceId = DMA_DEV_ID; Cfg.BaseAddr = MANUAL_DMA_BASEADDR;
    Cfg.HasMm2S = 0; Cfg.HasS2Mm = 1; Cfg.HasSg = 0;
    Cfg.Mm2sNumChannels = 0; Cfg.S2MmNumChannels = 1;
    Cfg.Mm2SBurstSize = 0; Cfg.S2MmBurstSize = 16;
    Cfg.MicroDmaMode = 0; Cfg.AddrWidth = 32;

    Status = XAxiDma_CfgInitialize(&AxiDma, &Cfg);
    if (Status != XST_SUCCESS) { return XST_FAILURE; }

    XAxiDma_Reset(&AxiDma);
    while (Timeout) { if (XAxiDma_ResetIsDone(&AxiDma)) break; Timeout--; }

    XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
    return XST_SUCCESS;
}

int transfer_data(void) {
    static int idle_counter = 0;
    static u32 previous_frame_word0 = 0xFFFFFFFF;

    if (!dma_initialized) {
        if (init_dma_engine() == XST_SUCCESS) { dma_initialized = 1; }
        else { dma_initialized = -1; return -1; }
    }
    if (dma_initialized == -1) return 0;

    volatile u32 *RxBuffer = (u32 *)RX_BUFFER_BASE_ADDR;

    if (!dma_transfer_submitted) {
        Xil_DCacheInvalidateRange((INTPTR)(void *)RxBuffer, PACKET_BYTE_SIZE);
        if (XAxiDma_SimpleTransfer(&AxiDma, (INTPTR)(void *)RxBuffer, PACKET_BYTE_SIZE, XAXIDMA_DEVICE_TO_DMA) == XST_SUCCESS) {
            dma_transfer_submitted = 1;
        }
        return 0;
    }

    u32 dma_sr = XAxiDma_ReadReg(AxiDma.RegBase, XAXIDMA_RX_OFFSET + XAXIDMA_SR_OFFSET);
    if (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) || !(dma_sr & XAXIDMA_IRQ_IOC_MASK)) {
        if (++idle_counter >= 2000000) { idle_counter = 0; xil_printf("[HEARTBEAT] Idle...\r\n"); }
        return 0;
    }

    idle_counter = 0;
    Xil_DCacheInvalidateRange((INTPTR)(void *)RxBuffer, PACKET_BYTE_SIZE);

    // Capture the 7 words sent out by your modified AXI Bridge architecture
    u32 word0 = RxBuffer[0]; u32 word1 = RxBuffer[1]; u32 word2 = RxBuffer[2];
    u32 word3 = RxBuffer[3]; u32 word4 = RxBuffer[4]; u32 word5 = RxBuffer[5];
    u32 word6 = RxBuffer[6]; // FIXED: Word 6 captures your status lines [bits 4 downto 0]

    XAxiDma_WriteReg(AxiDma.RegBase, XAXIDMA_RX_OFFSET + XAXIDMA_SR_OFFSET, dma_sr & XAXIDMA_IRQ_ALL_MASK);

    // Clear whole 7-word memory pool segment
    RxBuffer[0] = 0; RxBuffer[1] = 0; RxBuffer[2] = 0; RxBuffer[3] = 0;
    RxBuffer[4] = 0; RxBuffer[5] = 0; RxBuffer[6] = 0;
    Xil_DCacheFlushRange((INTPTR)(void *)RxBuffer, PACKET_BYTE_SIZE);
    dma_transfer_submitted = 0;

    if ((word0 != 0 || word1 != 0) && (word0 != previous_frame_word0)) {
        previous_frame_word0 = word0;
        QtTelemetryPkt payload;

        payload.Pa_LSB = (uint8_t)(word0 & 0xFF);         payload.Pa_MSB = (uint8_t)((word0 >> 8) & 0xFF);
        payload.Pb_LSB = (uint8_t)((word0 >> 16) & 0xFF); payload.Pb_MSB = (uint8_t)((word0 >> 24) & 0xFF);
        payload.byte12 = (uint8_t)(word1 & 0xFF);         payload.byte13 = (uint8_t)((word1 >> 8) & 0xFF);
        payload.ch9_byte12 = (uint8_t)((word1 >> 16) & 0xFF); payload.ch9_byte13 = (uint8_t)((word1 >> 24) & 0xFF);

        payload.ch0_otrm01 = (uint8_t)(word2 & 0xFF);     payload.ch0_otrm23 = (uint8_t)((word2 >> 8) & 0xFF);
        payload.ch0_otrm45 = (uint8_t)((word2 >> 16) & 0xFF); payload.ch0_otrm67 = (uint8_t)((word2 >> 24) & 0xFF);
        payload.ch0_otrm89 = (uint8_t)(word3 & 0xFF);     payload.ch0_otrm1011 = (uint8_t)((word3 >> 8) & 0xFF);
        payload.ch0_otrm1213 = (uint8_t)((word3 >> 16) & 0xFF); payload.ch0_otrm1415 = (uint8_t)((word3 >> 24) & 0xFF);

        payload.ch9_otrm01 = (uint8_t)(word4 & 0xFF);     payload.ch9_otrm23 = (uint8_t)((word4 >> 8) & 0xFF);
        payload.ch9_otrm45 = (uint8_t)((word4 >> 16) & 0xFF); payload.ch9_otrm67 = (uint8_t)((word4 >> 24) & 0xFF);
        payload.ch9_otrm89 = (uint8_t)(word5 & 0xFF);     payload.ch9_otrm1011 = (uint8_t)((word5 >> 8) & 0xFF);
        payload.ch9_otrm1213 = (uint8_t)((word5 >> 16) & 0xFF); payload.ch9_otrm1415 = (uint8_t)((word5 >> 24) & 0xFF);

        // FIXED: Decode bits 4 downto 0 from word6 matching your exact configuration layout
        payload.rfif_fwd_pwr_sts  = (uint8_t)(word6 & 0x01);
        payload.rfif_slb_out_sts  = (uint8_t)((word6 >> 1) & 0x01);
        payload.rfif_temp_sts     = (uint8_t)((word6 >> 2) & 0x01);
        payload.rfif_path_cal_sts = (uint8_t)((word6 >> 3) & 0x01);
        payload.rfif_amp_cal_sts  = (uint8_t)((uint8_t)(word6 >> 4) & 0x01);

        xil_printf("[PARSED] Pa:0x%02X%02X Pb:0x%02X%02X | B12:0x%02X B13:0x%02X | Ch9-B12:0x%02X Ch9-B13:0x%02X\r\n",
                   payload.Pa_MSB, payload.Pa_LSB, payload.Pb_MSB, payload.Pb_LSB, payload.byte12, payload.byte13, payload.ch9_byte12, payload.ch9_byte13);
        xil_printf("[OTRM CH0] 01:0x%02X 23:0x%02X 45:0x%02X 67:0x%02X 89:0x%02X 1011:0x%02X 1213:0x%02X 1415:0x%02X\r\n",
                   payload.ch0_otrm01, payload.ch0_otrm23, payload.ch0_otrm45, payload.ch0_otrm67, payload.ch0_otrm89, payload.ch0_otrm1011, payload.ch0_otrm1213, payload.ch0_otrm1415);
        xil_printf("[OTRM CH9] 01:0x%02X 23:0x%02X 45:0x%02X 67:0x%02X 89:0x%02X 1011:0x%02X 1213:0x%02X 1415:0x%02X\r\n",
                   payload.ch9_otrm01, payload.ch9_otrm23, payload.ch9_otrm45, payload.ch9_otrm67, payload.ch9_otrm89, payload.ch9_otrm1011, payload.ch9_otrm1213, payload.ch9_otrm1415);

        // FIXED: Log status bits parameters inside serial terminal diagnostics console
        xil_printf("[RFIF STATUS] FWD_PWR:%d | SLB_OUT:%d | TEMP:%d | PATH_CAL:%d | AMP_CAL:%d\r\n",
                   payload.rfif_fwd_pwr_sts, payload.rfif_slb_out_sts, payload.rfif_temp_sts, payload.rfif_path_cal_sts, payload.rfif_amp_cal_sts);

        if (app_pcb != NULL) {
            struct pbuf *p = pbuf_alloc(PBUF_TRANSPORT, sizeof(QtTelemetryPkt), PBUF_RAM);
            if (p != NULL) { memcpy(p->payload, &payload, sizeof(QtTelemetryPkt)); udp_sendto(app_pcb, p, &gui_ipaddr, 7); pbuf_free(p); }
        }
    }
    return 0;
}

void print_app_header(void) { xil_printf("\n\r----- lwIP Standalone Dual DMA Telemetry Server ------\n\r"); }
void udp_recv_callback(void *arg, struct udp_pcb *pcb, struct pbuf *p, ip_addr_t *addr, u16_t port) { (void)arg; if (p != NULL) { udp_sendto(pcb, p, addr, port); pbuf_free(p); } }
int start_application(void) {
    unsigned port = 7; app_pcb = udp_new(); if (!app_pcb) return -1;
    if (udp_bind(app_pcb, IP_ADDR_ANY, port) != ERR_OK) { udp_remove(app_pcb); return -2; }
    IP4_ADDR(&gui_ipaddr, 192, 168, 1, 20); udp_recv(app_pcb, (udp_recv_fn)udp_recv_callback, NULL); return 0;
}
