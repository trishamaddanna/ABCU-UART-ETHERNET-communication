#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QLabel>
#include <QScrollArea>
#include <QWidget>
#include <QTabWidget>
#include <QComboBox>
#include <QUdpSocket>
#include <QMessageBox>
#include <QNetworkInterface>
#include <QHostAddress>
#include <cmath>
#include <QFileDialog>
#include <QThread>
#include "receive.h"
#include "otrm.h"
#include "headers.h"
#include <QTimer>
#include <QVector>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE


class FileTransferWorker : public QObject {
    Q_OBJECT
public:
    QString filePath;
    QHostAddress address;
    quint16 port;
    FileTransferWorker(QString path, QHostAddress addr, quint16 p)
        : filePath(path), address(addr), port(p) {}

public slots:
    void process() {
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly)) {
            emit errorOccurred("Cannot open file!");
            return;
        }

        QByteArray originalData = file.readAll();
        file.close();

        qDebug() << "File Size:" << originalData.size();

        QUdpSocket socket;
        const int MAX_UDP_PAYLOAD = 1400;
        const QString idPrefix = "BIN";
        const int IDENTIFIER_SIZE = 3 + sizeof(quint16);
        const int DATA_CHUNK_SIZE = MAX_UDP_PAYLOAD - IDENTIFIER_SIZE;
        int totalPackets = (originalData.size() + DATA_CHUNK_SIZE - 1) / DATA_CHUNK_SIZE;

        for (int i = 0; i < totalPackets; ++i)
        {
            int offset = i * DATA_CHUNK_SIZE;
            int currentChunkSize = qMin(DATA_CHUNK_SIZE, originalData.size() - offset);

            QByteArray packet;
            packet.append(idPrefix);
            quint16 idValue = static_cast<quint16>(i + 1);
            packet.append(reinterpret_cast<const char*>(&idValue), sizeof(idValue));
            packet.append(originalData.mid(offset, currentChunkSize));

            socket.writeDatagram(packet, address, port);
            QThread::msleep(50); // delay
        }
        emit finished(totalPackets);
    }

signals:
    void finished(int count);
    void errorOccurred(QString msg);
};

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    // Locate this section within mainwindow.h near the slots block declaration:
    // Inside mainwindow.h private slots block:
    private slots:
        void arrayGeometryType(int index);
        void on_pushButton_clicked();
        void onErrorOccurred(QAbstractSocket::SocketError);
        void on_pushButton_2_clicked();
        void on_pushButton_3_clicked();
        void resetLabelColors();
        void updateNetworkStatus();
        void vUpdateData(const QString &hexString); // <-- CHANGED PARAMETER TYPE TO QString HERE

  // <-- CHANGED PARAMETER TYPE HERE

        void show_Otrmgcsts();
        void vDataReceived(char* ucBuff);


        void on_pb_cal_in_clicked();

private:
    int currentRows = 64;
    int currentCols = 64;
    Ui::MainWindow *ui;
    QLabel *label[64][64];
    QScrollArea *scrollArea;
    QWidget *containerWidget;
    QComboBox *typeSelector;
    void arrayGeometry(int row, int col);
    QUdpSocket *socket;
    QString selectedFilePath;
    QLabel *arrayElementLabel;
    QLineEdit *editX;
    QLineEdit *editY;
    QPushButton *btnOnOff;
    bool isArrayOn = true;
    QComboBox *elementIndexSelector;
    void updateElementSelectorRange(int maxElements);
    void updateInfoLabel(int r, int c);
    QLabel *infoLabel;
    void updateSelection();
//    void setElementState(int r, int c, bool active);
    QPushButton *btnToggle;
    QComboBox *selectionMode;

    receive *m_receive;
    QThread *m_thread;

    Otrm *m_otrmobj[32];

    QPushButton *m_pbotrmgcsts[32];
    QLabel *m_Gcled[32];

    int i;

    ST_OTRM_DATA stOtrmData;
    bool isBitCheckMain(short data,int position);
    unsigned char cntGreen = 0;
    unsigned char cntRed = 0;

    void DisplayRFIFStatus(quint8 val, QLabel *label);

     int GCbtnid;
     QVector<int> vecGcBtn;

     bool bCal =0;
public:
       void setElementState(int r, int c, bool active, int gcid=0);




};
#endif // MAINWINDOW_H
