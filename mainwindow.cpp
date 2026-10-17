#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QDebug>
#include <QBoxLayout>
#include <QTimer>
extern QString RedLabel;
extern QString GreenLabel ;
extern QString GreyLabel;
QString YellowLabel = "min-width: 20px;\nmax-width: 20px;\nmin-height: 20px;\nmax-height: 20px;\nborder-radius:12px;\nborder:2px solid yellow;\nbackground-color: yellow;\npadding: opx;\nmargin: opx;\nqproperty-text: " ";";
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{


    for(int i = 0; i < currentRows; ++i)
        for(int j = 0; j < currentRows; ++j)
            label[i][j] = nullptr;

    ui->setupUi(this);

    //    ui->label_59->setFixedSize(30,30);
    //    ui->label_59->setText("");
    //    ui->label_59->setStyleSheet(
    //                "background-color: #FF3B30;"
    //                "border: 2px solid #C71A11;"
    //                "border-radius: 15px;");

    updateNetworkStatus();

    QWidget *tab1 = ui->tabWidget->widget(0);

    QVBoxLayout *tabLayout = new QVBoxLayout(tab1);
    tabLayout->setContentsMargins(10, 10, 10, 10);
    tabLayout->setSpacing(10);

    QHBoxLayout *topControlRow = new QHBoxLayout();

    // --- BEFORE (Buggy Code) ---
    // QHBoxLayout *selectorGroup = new QHBoxLayout();
    // receive *m_receive = new receive();
    // QThread *m_thread = new QThread();

    // --- AFTER (Corrected Code) ---
    QHBoxLayout *selectorGroup = new QHBoxLayout();

    // REMOVED 'receive *' and 'QThread *' to use class global member instances
    m_receive = new receive();
    m_thread = new QThread();

    m_receive->moveToThread(m_thread);
    connect(m_thread, &QThread::started, m_receive, &receive::vInitSocket);
    m_thread->start();

    connect(m_receive, &receive::sigData, this, &MainWindow::vUpdateData);

    QLabel *selectorLabel = new QLabel("Set Geometry Mode:", tab1);
    selectorLabel->setStyleSheet("font-size: 12px;");

    typeSelector = new QComboBox(tab1);
    typeSelector->addItem("64 x 64", 0);
    typeSelector->addItem("16 x 8", 1);
    typeSelector->setFixedWidth(70);
    typeSelector->setStyleSheet("font-size: 12px;");
    selectorGroup->addWidget(selectorLabel);
    selectorGroup->addWidget(typeSelector);
    selectorGroup->addStretch();

    QFrame *line = new QFrame();
    line->setFrameShape(QFrame::VLine);
    line->setFrameShadow(QFrame::Sunken);
    topControlRow->addLayout(selectorGroup);
    topControlRow->addWidget(line);

    QLabel *modeLabel = new QLabel("Select Mode:", tab1);
    modeLabel->setStyleSheet("font-size: 12px;");

    selectionMode = new QComboBox(tab1);
    selectionMode->addItem("Element", 0);
    selectionMode->addItem("Row", 1);
    selectionMode->addItem("Column", 2);
    selectionMode->setFixedWidth(80);
    selectionMode->setStyleSheet("font-size: 12px;");
    selectorGroup->addWidget(modeLabel);
    selectorGroup->addWidget(selectionMode);

    arrayElementLabel = new QLabel("Array Element Index:", tab1);
    arrayElementLabel->setStyleSheet("font-size: 12px; margin-left: 10px;");
    topControlRow->addWidget(arrayElementLabel);

    elementIndexSelector = new QComboBox(tab1);
    elementIndexSelector->setFixedWidth(60);
    elementIndexSelector->setStyleSheet("font-size: 12px;");
    topControlRow->addWidget(elementIndexSelector);

    infoLabel = new QLabel("(Row,Col)", tab1);
    infoLabel->setStyleSheet("font-size: 12px;");
    topControlRow->addWidget(infoLabel);

    btnToggle = new QPushButton("OFF", tab1);
    btnToggle->setFixedWidth(60);
    btnToggle->setStyleSheet("background-color: #e74c3c; color: white; font-weight: bold; border-radius: 4px;");
    topControlRow->addWidget(btnToggle);

    QPushButton *btnClearAll = new QPushButton("Clear All", tab1);
    btnClearAll->setFixedWidth(60);
    btnClearAll->setStyleSheet("background-color: #3498db; color: white; font-weight: bold; border-radius: 4px;");
    topControlRow->addWidget(btnClearAll);

    connect(btnToggle, &QPushButton::clicked, this, [this]()
    {
        /*  int idx = elementIndexSelector->currentIndex();
        int mode = selectionMode->currentIndex();
        int rr = (typeSelector->currentIndex() == 0) ? 64 : 16;


        if (mode == 0) { // SINGLE ELEMENT
            int r = idx % rr;
            int c = idx / rr;
            bool currentState = label[r][c]->property("active").toBool();
            setElementState(r, c, !currentState);

            // Update button text for next click
            bool newState = !currentState;
            btnToggle->setText(newState ? "ON" : "OFF");
            btnToggle->setStyleSheet(newState ? "background-color: #2ecc71; color: white;" : "background-color: #e74c3c; color: white;");
        }
        else if (mode == 1) { // WHOLE ROW
            int r = idx;
            // Use the first element of the row to check if the row is currently "ON"
            bool rowIsOn = label[r][0]->property("active").toBool();
            bool targetState = !rowIsOn;

            for (int j = 0; j < currentCols; j++) {
                setElementState(r, j, targetState);
            }
            btnToggle->setText(targetState ? "ON" : "OFF");
            btnToggle->setStyleSheet(targetState ? "background-color: #2ecc71; color: white;" : "background-color: #e74c3c; color: white;");
        }
        else if (mode == 2) { // WHOLE COLUMN
            int c = idx;
            // Use the first element of the column to check if the column is currently "ON"
            bool colIsOn = label[0][c]->property("active").toBool();
            bool targetState = !colIsOn;

            for (int i = 0; i < currentRows; i++) {
                setElementState(i, c, targetState);

            }
            btnToggle->setText(targetState ? "ON" : "OFF");
            btnToggle->setStyleSheet(targetState ? "background-color: #2ecc71; color: white;" : "background-color: #e74c3c; color: white;");



        }*/

        //        for(int i=0;i<16;i++)
        //            if(i<9)
        //                setElementState(i, 0, true);
        //            else
        //                setElementState(i,0,true);
        //  updateSelection();

        for(int k=0;k<8;k++)
            setElementState(k, 0, true);
    });



    connect(selectionMode, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int mode)
    {
        elementIndexSelector->blockSignals(true);
        elementIndexSelector->clear();

        int maxVal = 0;
        if (mode == 0) { // Element Mode
            maxVal = currentRows * currentCols;
        } else if (mode == 1) { // Row Mode
            maxVal = currentRows;
        } else if (mode == 2) { // Column Mode
            maxVal = currentCols;
        }

        for (int i = 1; i <= maxVal; ++i) {
            elementIndexSelector->addItem(QString::number(i));
        }
        elementIndexSelector->setCurrentIndex(0);
        elementIndexSelector->blockSignals(false);
        this->updateSelection();
    });

    connect(elementIndexSelector, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int index)
    {
        this->updateSelection();

        int mode = selectionMode->currentIndex();
        int rr = (typeSelector->currentIndex() == 0) ? 64 : 16;

        if (mode == 0)
        {
            int r = index % rr;
            int c = index / rr;
            if (r >= 0 && r < currentRows && c >= 0 && c < currentCols)
                setElementState(r, c, true);
        }
        else if (mode == 1)
        {
            int r = index;
            if (r >= 0 && r < currentRows)
            {
                for (int j = 0; j < currentCols; j++)
                    setElementState(r, j, true);
            }
        }
        else if (mode == 2)
        {
            int c = index;
            if (c >= 0 && c < currentCols)
            {
                for (int i = 0; i < currentRows; i++)
                    setElementState(i, c, true);
            }
        }

        btnToggle->setText("ON");
        btnToggle->setStyleSheet("background-color: #2ecc71; color: white; font-weight: bold; border-radius: 4px;");
    });

    connect(typeSelector, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int)
    {
        QTimer::singleShot(0, this, &MainWindow::updateSelection);
    });

    connect(btnClearAll, &QPushButton::clicked, this, [this]()
    {
        resetLabelColors();
    });

    tabLayout->addLayout(topControlRow);

    QLabel *titleLabel = new QLabel("Array Geometry", tab1);
    titleLabel->setAlignment(Qt::AlignCenter);
    titleLabel->setStyleSheet("font-size: 20px; font-weight: bold; color: black; padding: 10px;");

    tabLayout->addWidget(titleLabel);

    scrollArea = new QScrollArea(tab1);
    scrollArea->setWidgetResizable(false);
    scrollArea->setFrameShape(QFrame::NoFrame);

    tab1->setLayout(tabLayout);
    tab1->layout()->addWidget(scrollArea);

    containerWidget = new QWidget();
    scrollArea->setWidget(containerWidget);

    connect(typeSelector, QOverload<int>::of(&QComboBox::currentIndexChanged),this, &MainWindow::arrayGeometryType);

    arrayGeometryType(0);

    // --- LOCATE THIS BLOCK INSIDE YOUR CONSTRUCTOR (Lines 164-167) ---
    // --- BEFORE ---
    //    ui->comboBox->addItem("Normal", "01");
    //    ui->comboBox->addItem("Calibration", "02");
    //    ui->comboBox_2->addItem("Transmission", "01");
    //    ui->comboBox_2->addItem("Reception", "02");

    // --- AFTER (Corrected Initialization) ---
    ui->comboBox->addItem("Normal", "01");
    ui->comboBox->addItem("Calibration", "02");
    ui->comboBox_2->addItem("Transmission", "01");
    ui->comboBox_2->addItem("Reception", "02");

    // Clear and populate your dedicated MAIN / REDUNDANT combobox.
    // Try using 'comboBox_Main_Redundant' if you renamed it, or check if it's comboBox_4
    // For this fix, let's explicitly target the correct UI combo box object:
//    if (ui->comboBox_3) {
//        ui->comboBox_3->clear();
//        ui->comboBox_3->addItem("00-Redundant", 0);
//        ui->comboBox_3->addItem("01-Main", 1);
//    }
    // Index maps string to numeric 0x01


    socket = new QUdpSocket(this);
    connect(socket, SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(onErrorOccurred(QAbstractSocket::SocketError)));


    /*Ashwini*/

    memset(&stOtrmData,0,sizeof(ST_OTRM_DATA));
    connect(m_receive,&receive::SigOtrmData,this,&MainWindow::vDataReceived);

    QPushButton *otrmbtn[32] = {ui->pb_OtrmGC1,ui->pb_OtrmGC2,ui->pb_OtrmGC3,ui->pb_OtrmGC4,ui->pb_OtrmGC5,ui->pb_OtrmGC6,ui->pb_OtrmGC7,ui->pb_OtrmGC8,
                                ui->pb_OtrmGC9,ui->pb_OtrmGC10,ui->pb_OtrmGC11,ui->pb_OtrmGC12,ui->pb_OtrmGC13,ui->pb_OtrmGC14,ui->pb_OtrmGC15,ui->pb_OtrmGC16
                                ,ui->pb_OtrmGC17,ui->pb_OtrmGC18,ui->pb_OtrmGC19,ui->pb_OtrmGC20,ui->pb_OtrmGC21,ui->pb_OtrmGC22,ui->pb_OtrmGC23,ui->pb_OtrmGC24
                                ,ui->pb_OtrmGC25,ui->pb_OtrmGC26,ui->pb_OtrmGC27,ui->pb_OtrmGC28,ui->pb_OtrmGC29,ui->pb_OtrmGC30,ui->pb_OtrmGC31,ui->pb_OtrmGC32};

    QLabel *ledlable[32]={ui->Gc_Led1,ui->Gc_Led2,ui->Gc_Led3,ui->Gc_Led4,ui->Gc_Led5,ui->Gc_Led6,ui->Gc_Led7,ui->Gc_Led8
                          ,ui->Gc_Led9,ui->Gc_Led10,ui->Gc_Led11,ui->Gc_Led12,ui->Gc_Led13,ui->Gc_Led14,ui->Gc_Led15,ui->Gc_Led16
                          ,ui->Gc_Led17,ui->Gc_Led18,ui->Gc_Led19,ui->Gc_Led20,ui->Gc_Led21,ui->Gc_Led22,ui->Gc_Led23,ui->Gc_Led24
                          ,ui->Gc_Led25,ui->Gc_Led26,ui->Gc_Led27,ui->Gc_Led28,ui->Gc_Led29,ui->Gc_Led30,ui->Gc_Led31,ui->Gc_Led32};

    for(int i= 0;i< 32;i++)
    {
        m_otrmobj[i] = new Otrm();
        m_pbotrmgcsts[i] = otrmbtn[i];
        m_Gcled[i]=ledlable[i];
        m_Gcled[i]->setStyleSheet(GreyLabel);
        m_pbotrmgcsts[i]->setObjectName(QString::number(i));
    }
    for(i = 0; i < 32;i++ ){
        connect(m_pbotrmgcsts[i],&QPushButton::clicked,this,&MainWindow::show_Otrmgcsts);
    }


}


MainWindow::~MainWindow()
{
    delete ui;
}


void MainWindow::vDataReceived(char *ucBuff)
{
   // stOtrmData = *(ST_OTRM_DATA *) ucBuff;


    memcpy(&stOtrmData,ucBuff,sizeof(ST_OTRM_DATA));


    qDebug()<<"gc1"<<stOtrmData.Byte1;
    qDebug()<<"gc1"<<stOtrmData.Gc[1];
    qDebug()<<"gc1"<<stOtrmData.Gc[0];
    //    m_otrmobj[0]->vOtrmData(stOtrmData.Gc_01);
    //    m_otrmobj[8]->vOtrmData(stOtrmData.Gc_09);

     m_otrmobj[0]->vOtrmData(stOtrmData.Gc[0]);
     m_otrmobj[8]->vOtrmData(stOtrmData.Gc[1]);

//     if(GCbtnid == 8)
//         GCbtnid = 1;

     for(int j=0;j<2;j++){
        //m_otrmobj[j]->vOtrmData(stOtrmData.Gc[j]);

        cntGreen = 0;
        cntRed = 0;

        for(int i=0; i<16; i++){

            if( isBitCheckMain(stOtrmData.Gc[j],i)){
                cntGreen++;

                if(j == 0 )
                    for(int x = 0;x<16;x++){

                        if(x == i){
                            if(i % 2 ==0){
                                for(int k=0;k<8;k++)
                                    setElementState(k, x/2, true);
                            }
                            else{
                                for(int k=8;k<16;k++)
                                    setElementState(k, x/2, true);
                            }
                        }
                    }

            }
            else{
                if(j == 0 ){
                    for(int x = 0;x<16;x++){

                        if(x == i){
                            if(i % 2 ==0){
                                for(int k=0;k<8;k++)
                                    setElementState(k, x/2, false);
                            }
                            else{
                                for(int k=8;k<16;k++)
                                    setElementState(k, x/2, false);
                            }
                        }
                    }
                }

                cntRed++;
            }


        }
        if(j == 1)
            j = 8;

        if(cntGreen == 16){
            m_Gcled[j]->setStyleSheet(GreenLabel);
        }else if(cntRed ==16){
            m_Gcled[j]->setStyleSheet(RedLabel);
        }else{
            m_Gcled[j]->setStyleSheet(YellowLabel);
        }

    }

     DisplayRFIFStatus(stOtrmData.ucCalAmpHS,ui->CalAmpHS);
     DisplayRFIFStatus(stOtrmData.ucCalPathPS,ui->CalPathPwS);
     DisplayRFIFStatus(stOtrmData.ucPowerOnVS,ui->PwonVS);
     DisplayRFIFStatus(stOtrmData.ucTempStatus,ui->TempStatus);
     DisplayRFIFStatus(stOtrmData.ucTransmitPathHS,ui->transmitPH);


}

void MainWindow::DisplayRFIFStatus(quint8 val, QLabel *label)
{
    if(val == 1)
    {
        label->setStyleSheet(GreenLabel);
    }
    else{
        label->setStyleSheet(RedLabel);
    }
}

bool MainWindow::isBitCheckMain(short data, int position)
{
    if((data >> position) & 1){
        return true;
    }
    else{
        return false;
    }
}



void MainWindow::show_Otrmgcsts()
{
    // m_otrmobj->show();

    GCbtnid = this->sender()->objectName().toInt();
    qDebug()<<"btnid"<<GCbtnid<<endl;
    vecGcBtn.push_back(GCbtnid);

    m_otrmobj[GCbtnid]->setGroupBoxText(GCbtnid);
    m_otrmobj[GCbtnid]->show();

}

void MainWindow::setElementState(int r, int c, bool active, int gcid)
{

    for(int i =0;i<32;i++){
        if( gcid == i){
            if (r >= 0 && r < currentRows && c >= 0 && c < currentCols && label[r][c] != nullptr)
            {
                if (active)
                {
                    label[r][c]->setStyleSheet("background-color: #2ecc71; border-radius:6px;");
                    label[r][c]->setProperty("active", true);
                }
                else
                {
                    label[r][c]->setStyleSheet("background-color: blue; border-radius: 6px;");
                    label[r][c]->setProperty("active", false);
                }
            }
        }
    }

}


void MainWindow::updateSelection()
{
    int idx = elementIndexSelector->currentIndex();
    int mode = selectionMode->currentIndex();
    int rr = (typeSelector->currentIndex() == 0) ? 64 : 16;

    if (mode == 0) // Element Mode
    {
        int r = idx % rr;
        int c = idx / rr;
        infoLabel->setText(QString("(%1,%2)").arg(r + 1).arg(c + 1));
    }
    else if (mode == 1) // Row Mode
    {
        infoLabel->setText(QString("Row: %1").arg(idx + 1));
    }
    else if (mode == 2) // Column Mode
    {
        infoLabel->setText(QString("Col: %1").arg(idx + 1));
    }
}

void MainWindow::updateElementSelectorRange(int maxElements)
{
    elementIndexSelector->blockSignals(true);
    elementIndexSelector->clear();
    for (int i = 1; i <= maxElements; ++i)
    {
        elementIndexSelector->addItem(QString::number(i));

    }
    elementIndexSelector->setCurrentIndex(0);
    elementIndexSelector->blockSignals(false);

}

void MainWindow::resetLabelColors()
{
    for (int i = 0; i < currentRows; i++)
    {
        for (int j = 0; j < currentCols; j++)
        {
            if (label[i][j] != nullptr)
            {
                label[i][j]->setStyleSheet("background-color:blue; border-radius:6px;");
                label[i][j]->setProperty("active", false);
            }
        }
    }
    btnToggle->setText("OFF");
    btnToggle->setStyleSheet("background-color: #e74c3c; color: white; font-weight: bold; border-radius: 4px;");
}

void MainWindow:: arrayGeometryType(int index)
{
    if(index == 0)
    {
        arrayGeometry(64,64);
        updateElementSelectorRange(4096);
    }
    else
    {
        arrayGeometry(16,8);
        updateElementSelectorRange(128);
    }
}

void MainWindow:: arrayGeometry(int row, int col)
{
    QApplication::processEvents();

    infoLabel->setText("(Row,Col)");

    for (int i = 0; i < currentRows; i++)
    {
        for (int j = 0; j < currentCols; j++)
        {
            if (label[i][j])
            {
                label[i][j] = nullptr;
            }
        }
    }
    currentRows = row;
    currentCols = col;

    QList<QObject*> children = containerWidget->children();
    for (QObject* child : children)
    {
        if (qobject_cast<QFrame*>(child))
        {
            child->deleteLater();
        }
    }

    bool isLarge = (row > 20);
    const int asize = 12;
    const int gapX = 28;
    const int gapY = 28;
    const int offset_x = gapX / 2;
    const int margin = 20;

    int totalWidth = (col * gapX) + offset_x + margin + asize;
    int totalHeight = (row * gapY) + margin + asize;
    containerWidget->resize(totalWidth, totalHeight);
    containerWidget->updateGeometry();

    QFrame *borderFrame = new QFrame(containerWidget);
    borderFrame->setGeometry(0, 0, totalWidth, totalHeight);
    borderFrame->setStyleSheet("QFrame { border: 4px solid black; border-radius: 10px; }");
    borderFrame->show();

    for (int i = 0; i < row; i++)
    {
        for (int j = 0; j < col; j++)
        {
            label[i][j] = new QLabel(containerWidget);
            label[i][j]->setProperty("active", false);
            label[i][j]->setStyleSheet(QString("background-color:blue; border-radius:%1px").arg(asize/2));
            int xPos = margin + (j * gapX);
            if (i % 2 != 0)
            {
                xPos += offset_x;
            }
            int yPos = (totalHeight - margin) - (i * gapY) - asize;
            if (yPos < 0)
            {
                yPos = 0;
            }
            label[i][j]->setGeometry(xPos, yPos, asize, asize);
            label[i][j]->setToolTip(QString("<div style='background-color: #333; color: white; padding: 5px;'>"
                                            "<b>Array Position</b><br>"
                                            "<span style='color: #00FF00;'>X:</span> %1<br>"
                                            "<span style='color: #00FFFF;'>Y:</span> %2"
                                            "</div>")
                                    .arg(i+1).arg(j+1));
            label[i][j]->show();
            int step = isLarge? 7 : 3;
            if (i % step == 0 && j % step == 0)
            {
                QLabel *coordLabel = new QLabel(containerWidget);
                coordLabel->setText(QString("(%1,%2)").arg(i+1).arg(j+1));
                coordLabel->setStyleSheet("color: black; font-size: 14px; font-weight: bold; background: transparent;");
                coordLabel->setAlignment(Qt::AlignCenter);
                coordLabel->setGeometry(xPos - 20, yPos + asize + 2, 60, 15);
                coordLabel->show();
            }
        }
    }
    scrollArea->viewport()->update();
    scrollArea->update();
    btnToggle->setText("OFF");
    btnToggle->setStyleSheet("background-color: #e74c3c; color: white; font-weight: bold; border-radius: 4px;");
}

void splitToParts(double val, qint16 &intPart, qint16 &decPart)
{
    //qDebug()<<"val"<<val<<"::"<<intPart<<"::"<<decPart<<endl;
    //    intPart = static_cast<qint8>(/*std::floor*/(val));
    //decPart = static_cast<qint16>(std::round((val + (-intPart)) *10 ));//roundoff add multiple zeros


    //   decPart = static_cast<qint8>(((val-intPart) * 100)); //without roundoff
    if(val<0){
        intPart = static_cast<qint16>(/*std::floor*/(val));
        decPart = static_cast<qint16>((-(val-intPart) * 100)); //without roundoff

    }else{
        intPart = static_cast<qint16>(std::floor(val));

        decPart = static_cast<qint16>(((val-intPart) * 100)); //without roundoff

    }

    // qDebug()<<"val int"<<intPart<<"::"<<val;
}



bool isNetworkAvailable()
{
    for (const QNetworkInterface &interface : QNetworkInterface::allInterfaces())
    {
        if (interface.flags().testFlag(QNetworkInterface::IsUp) && interface.flags().testFlag(QNetworkInterface::IsRunning))
        {
            for (const QHostAddress &address : interface.allAddresses())
            {
                if (!address.isLoopback() && address.protocol() == QAbstractSocket::IPv4Protocol)
                {
                    return true;
                }
            }
        }
    }
    return false;
}

void MainWindow::updateNetworkStatus()
{
    if (!isNetworkAvailable())
    {
        ui->label_19->setText("No Network Connection");
        ui->label_19->setStyleSheet("color: #e74c3c;");
    }
    else
    {
        ui->label_19->setText("Network Connected");
        ui->label_19->setStyleSheet("color: #27ae60;");
    }
}


void MainWindow::vUpdateData(const QString &hexString)
{
    if (hexString.isEmpty()) return;

    // 1. Calculate the byte count by checking the length of the string without spaces
    QString cleanHex = hexString;
    cleanHex.remove(' ');
    int byteCount = cleanHex.length() / 2;

    qDebug()<<"recv string"<<hexString<<endl;
    // 2. Render the data window cleanly based on what the background thread captures
//    if (byteCount >= 28) {
//        // Displays Channel 0 bytes followed immediately by Channel 9 bytes: (e.g. 0E 55 01 16 0F 00 12 34)
//        ui->Rx_data->setText(hexString);
//    }
//    else if (byteCount >= 8){
//           // Fallback padding if the hardware drops packets or sends the legacy 6-byte stream
//           ui->Rx_data->setText(hexString + " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00");
//       } else {
//        // Fallback padding if the hardware drops packets or sends the legacy 6-byte stream
//        ui->Rx_data->setText(hexString);
//    }

     ui->Rx_data->setText(hexString);

    ui->Rx_data->repaint();
    ui->Rx_data->update();

    // qDebug() << "[QT UI THREAD SUCCESS] Rx Message Monitor Dashboard Updated successfully:" ;


}


void MainWindow::on_pushButton_clicked()
{
    updateNetworkStatus();
    if (!isNetworkAvailable())
    {
        ui->statusLabel->setText("Failed to Send");
        ui->statusLabel->setStyleSheet("color: #e74c3c;");
        return;
    }
    ui->doubleSpinBox->interpretText();
    ui->doubleSpinBox_2->interpretText();
    ui->doubleSpinBox_3->interpretText();
    double v1 = ui->doubleSpinBox->value();
    double v2 = ui->doubleSpinBox_2->value();
    double v3 = ui->doubleSpinBox_3->value();

    MyProtocolPacket packet;
    memset(&packet,0,sizeof(MyProtocolPacket));
    // 1st Byte position (System Mode) - Keep exactly as is
    packet.unMsgId = 0xAAA1;
    packet.mode = static_cast<quint8>(ui->comboBox->currentData().toString().toInt());

    // --- CHANGED FROM comboBox_3 TO comboBox_4 ---
    // This shifts the assignment pointer to read the correct Main/Redundant widget layout box!
    packet.redundancy_type = static_cast<quint8>(ui->comboBox_4->currentIndex());

    splitToParts(v3, packet.val3_int, packet.val3_dec);

    // ... (Keep your math processing logic, text transformations, and socket variables exactly the same) ...


    const double pi = M_PI;
    const double c = 299792458.0;
    const double DEG_TO_RAD = pi / 180.0;
    double v1_rad = v1 * DEG_TO_RAD;
    double v2_rad = v2 * DEG_TO_RAD;
    double Pa = (2.0*pi*v3*1000000000.0*std::cos(v1_rad)*std::sin(v2_rad))/c;
    double Pb = (2.0*pi*v3*1000000000.0*std::sin(v1_rad)*std::sin(v2_rad))/c;

    ui->pga->setText(QString::number(Pa, 'f', 2));
    ui->pgb->setText(QString::number(Pb, 'f', 2));
    double pgav1 = ui->pga->text().toDouble();
    double pgbv2 = ui->pgb->text().toDouble();


    splitToParts(pgav1, packet.val1_int, packet.val1_dec);
    splitToParts(pgbv2, packet.val2_int, packet.val2_dec);

    QHostAddress address(ui->lineEdit->text());
    quint16 port = static_cast<quint16>(ui->spinBox->value());

    qDebug() << "V1: " << packet.val1_int << "." << packet.val1_dec;
    qDebug() << "V2: " << packet.val2_int << "." << packet.val2_dec;
    qDebug() << "V3: " << packet.val3_int << "." << packet.val3_dec;

    //Gc 01 data
   // qDebug()<<"btnid"<<vecGcBtn<<endl;
    for(auto gc : vecGcBtn){
        if((gc+1) == 1){
            packet.Gc01 = 0x0001;
            QMap<int,int> mapOtrmGc1 = m_otrmobj[0]->getMapOnOff();

            if(mapOtrmGc1.contains(1)){
                switch(mapOtrmGc1.value(1)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm1 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm1 = 02;
                    break;
                default:
                    packet.Gc01_Otrm1 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(2)){
                switch(mapOtrmGc1.value(2)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm2 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm2 = 02;
                    break;
                default:
                    packet.Gc01_Otrm2 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(3)){
                switch(mapOtrmGc1.value(3)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm3 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm3 = 02;
                    break;
                default:
                    packet.Gc01_Otrm3 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(4)){
                switch(mapOtrmGc1.value(4)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm4 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm4 = 02;
                    break;
                default:
                    packet.Gc01_Otrm4 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(5)){
                switch(mapOtrmGc1.value(5)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm5 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm5 = 02;
                    break;
                default:
                    packet.Gc01_Otrm5 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(6)){
                switch(mapOtrmGc1.value(6)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm6 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm6 = 02;
                    break;
                default:
                    packet.Gc01_Otrm6 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(7)){
                switch(mapOtrmGc1.value(7)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm7 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm7 = 02;
                    break;
                default:
                    packet.Gc01_Otrm7 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(8)){
                switch(mapOtrmGc1.value(8)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm8 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm8 = 02;
                    break;
                default:
                    packet.Gc01_Otrm8 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(9)){
                switch(mapOtrmGc1.value(9)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm9 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm9 = 02;
                    break;
                default:
                    packet.Gc01_Otrm9 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(10)){
                switch(mapOtrmGc1.value(10)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm10 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm10 = 02;
                    break;
                default:
                    packet.Gc01_Otrm10 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(11)){
                switch(mapOtrmGc1.value(11)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm11 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm11 = 02;
                    break;
                default:
                    packet.Gc01_Otrm11 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(12)){
                switch(mapOtrmGc1.value(12)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm12 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm12 = 02;
                    break;
                default:
                    packet.Gc01_Otrm12 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(13)){
                switch(mapOtrmGc1.value(13)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm13 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm13 = 02;
                    break;
                default:
                    packet.Gc01_Otrm13 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(14)){
                switch(mapOtrmGc1.value(14)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm14 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm14 = 02;
                    break;
                default:
                    packet.Gc01_Otrm14 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(15)){
                switch(mapOtrmGc1.value(15)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm15 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm15 = 02;
                    break;
                default:
                    packet.Gc01_Otrm15 = 0;
                    break;
                }
            }

            if(mapOtrmGc1.contains(16)){
                switch(mapOtrmGc1.value(16)){
                case OTRM_TRUE:
                    packet.Gc01_Otrm16 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc01_Otrm16 = 02;
                    break;
                default:
                    packet.Gc01_Otrm16 = 0;
                    break;
                }
            }
        }


        if((gc+1) == 9){


            packet.Gc09 = 0x0009;
            QMap<int,int> mapOtrmGc9 = m_otrmobj[8]->getMapOnOff();

            if(mapOtrmGc9.contains(1)){
                switch(mapOtrmGc9.value(1)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm1 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm1 = 02;
                    break;
                default:
                    packet.Gc09_Otrm1 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(2)){
                switch(mapOtrmGc9.value(2)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm2 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm2 = 02;
                    break;
                default:
                    packet.Gc09_Otrm2 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(3)){
                switch(mapOtrmGc9.value(3)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm3 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm3 = 02;
                    break;
                default:
                    packet.Gc09_Otrm3 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(4)){
                switch(mapOtrmGc9.value(4)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm4 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm4 = 02;
                    break;
                default:
                    packet.Gc09_Otrm4 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(5)){
                switch(mapOtrmGc9.value(5)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm5 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm5 = 02;
                    break;
                default:
                    packet.Gc09_Otrm5 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(6)){
                switch(mapOtrmGc9.value(6)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm6 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm6 = 02;
                    break;
                default:
                    packet.Gc09_Otrm6 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(7)){
                switch(mapOtrmGc9.value(7)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm7 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm7 = 02;
                    break;
                default:
                    packet.Gc09_Otrm7 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(8)){
                switch(mapOtrmGc9.value(8)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm8 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm8 = 02;
                    break;
                default:
                    packet.Gc09_Otrm8 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(9)){
                switch(mapOtrmGc9.value(9)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm9 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm9 = 02;
                    break;
                default:
                    packet.Gc09_Otrm9 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(10)){
                switch(mapOtrmGc9.value(10)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm10 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm10 = 02;
                    break;
                default:
                    packet.Gc09_Otrm10 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(11)){
                switch(mapOtrmGc9.value(11)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm11 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm11 = 02;
                    break;
                default:
                    packet.Gc09_Otrm11 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(12)){
                switch(mapOtrmGc9.value(12)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm12 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm12 = 02;
                    break;
                default:
                    packet.Gc09_Otrm12 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(13)){
                switch(mapOtrmGc9.value(13)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm13 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm13 = 02;
                    break;
                default:
                    packet.Gc09_Otrm13 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(14)){
                switch(mapOtrmGc9.value(14)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm14 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm14 = 02;
                    break;
                default:
                    packet.Gc09_Otrm14 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(15)){
                switch(mapOtrmGc9.value(15)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm15 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm15 = 02;
                    break;
                default:
                    packet.Gc09_Otrm15 = 0;
                    break;
                }
            }

            if(mapOtrmGc9.contains(16)){
                switch(mapOtrmGc9.value(16)){
                case OTRM_TRUE:
                    packet.Gc09_Otrm16 = 01;
                    break;
                case OTRM_FALSE:
                    packet.Gc09_Otrm16 = 02;
                    break;
                default:
                    packet.Gc09_Otrm16 = 0;
                    break;
                }
            }

        }

    }
    vecGcBtn.clear();

    packet.ucCalVal = bCal;

    QByteArray data(reinterpret_cast<const char*>(&packet), sizeof(packet));

    qDebug() << "Tx:" << data.toHex(' ');
    qDebug() << "Packet Size:" << data.size();

    QString hexString = data.toHex(' ').toUpper();
    ui->tx_data->setText(hexString);


    qint64 bytesSent = socket->writeDatagram(data, address, port);

    if (bytesSent != -1)
    {
        ui->statusLabel->setText("Command Sent");
        ui->statusLabel->setStyleSheet("color: #27ae60;");
    }
    else
    {
        ui->statusLabel->setText("Failed to Send");
        ui->statusLabel->setStyleSheet("color: #e74c3c;");
    }
}

void MainWindow::onErrorOccurred(QAbstractSocket::SocketError)
{
    ui->label_19->setText("Network Error");
    ui->label_19->setStyleSheet("color: #e74c3c;");
    QMessageBox::critical(this, "Network Error", socket->errorString());
}

void MainWindow::on_pushButton_2_clicked()
{
    QString file = QFileDialog::getOpenFileName(this, tr("Open File"),"", tr("Binary Files (*.bin);;All files (*.*)"));
    if (!file.isEmpty())
    {
        ui->lineEdit_2->setText(file);
        selectedFilePath = file;
    }
}

void MainWindow::on_pushButton_3_clicked()
{
    updateNetworkStatus();
    if (!isNetworkAvailable())
    {
        ui->label_18->setText("Failed to Send");
        ui->label_18->setStyleSheet("color: #e74c3c;");
        return;
    }

    if (selectedFilePath.isEmpty())
    {
        ui->label_18->setText("No file selected!");
        ui->label_18->setStyleSheet("color: #e74c3c;");
        return;
    }

    QHostAddress addr(ui->lineEdit->text());
    quint16 port = static_cast<quint16>(ui->spinBox->value());

    ui->label_18->setText("Sending...");
    ui->label_18->setStyleSheet("color: blue;");

    QThread* thread = new QThread;
    FileTransferWorker* worker = new FileTransferWorker(selectedFilePath, addr, port);
    worker->moveToThread(thread);

    connect(thread, &QThread::started, worker, &FileTransferWorker::process);

    connect(worker, &FileTransferWorker::finished, this, [this](int count)
    {
        ui->label_18->setText(QString("Sent %1 packets").arg(count));
        ui->label_18->setStyleSheet("color: green;");
    });

    connect(worker, &FileTransferWorker::errorOccurred, this, [this](QString msg)
    {
        ui->label_18->setText(msg);
        ui->label_18->setStyleSheet("color: red;");
    });

    connect(worker, &FileTransferWorker::finished, thread, &QThread::quit);
    connect(worker, &FileTransferWorker::errorOccurred, thread, &QThread::quit);
    connect(thread, &QThread::finished, worker, &QObject::deleteLater);
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);

    thread->start();
}


void MainWindow::on_pb_cal_in_clicked()
{
    //qDebug()<<"clicked"<<checked<<endl;

    if(ui->pb_cal_in->text() == "OFF"){
        ui->pb_cal_in->setText("ON");
        bCal = true;
    }
     else{
         ui->pb_cal_in->setText("OFF");
         bCal = false;
    }
}
