#include "receive.h"

receive::receive()
{
//    m_WatchDogTimer = new QTimer(this);
//    connect(m_WatchDogTimer,&QTimer::timeout,this,&receive::LinkFailStatus);
//    m_WatchDogTimer->start(1000);
}

void receive::vInitSocket()
{
    CMSRxSocket = new QUdpSocket(this);
    m_RxPort = 7;

    if(CMSRxSocket->bind(QHostAddress::AnyIPv4,m_RxPort) == 0)
    {
        qDebug()<<"Not Binded";
    }else
    {
        connect(CMSRxSocket,&QUdpSocket::readyRead,this,&receive::ReadDatagram);
        qDebug()<<"Bind11";
    }
}

void receive::ReadDatagram()
{
    while (CMSRxSocket->hasPendingDatagrams()) {
        qint64 size = CMSRxSocket->pendingDatagramSize();
        QByteArray Datagram;
        Datagram.resize(static_cast<int>(size));

        QHostAddress senderIp;
        quint16 senderPort;
        CMSRxSocket->readDatagram(Datagram.data(), Datagram.size(), &senderIp, &senderPort);

        char *data = Datagram.data();
        for(int i =0;i<Datagram.size();i++)
         qDebug()<<"datagram"<<QString::number(data[i],16)<<" ";
        qDebug()<<endl;
        // --- FIXED: Safe extraction framework prior to text transformation ---
        QString formattedHex;


        if (Datagram.size() >= 29) {
            // Explicitly clip out exactly the first 8 structural payload bytes
            formattedHex = Datagram.left(29).toHex(' ').toUpper();
           qDebug()<<"hex Val"<<formattedHex<<endl;
        }
        else {
//            // Safe legacy fallback translation layer
          formattedHex = Datagram.toHex(' ').toUpper();
        }
         //formattedHex = Datagram.toHex(' ').toUpper();

        qDebug() << "[QT BACKEND SUCCESS] Packet Captured!"
                 << "Raw Socket Size:" << size << "bytes"
                 << "| Transformed Hex Data String:" << formattedHex;

        // Emit the safe, thread-stable string across the cross-thread boundary layout safely
        emit sigData(formattedHex);
        emit SigOtrmData(Datagram.data());
    }
}



