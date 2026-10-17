#ifndef RECEIVE_H
#define RECEIVE_H

#include <QObject>
#include <QUdpSocket>
#include <QHostAddress>
#include <QTimer>
#include <QByteArray> // Added for container support
#include "headers.h"
class receive : public QObject
{
    Q_OBJECT
public:
    receive();

signals:
    // CHANGED: Transitioned from char* to safe deep-copied QByteArray reference
    void sigData(const QString &hexString); // Changed parameter footprint to a direct string
    void SigOtrmData(char *ucBuff);
     void vSendLinkStatus();
private slots:
    void ReadDatagram();
//    void  LinkFailStatus();

public slots:
     void  vInitSocket();

private:
    QUdpSocket *CMSRxSocket;
    unsigned short m_RxPort;
    QHostAddress m_MulticastIp;
    QTimer *m_WatchDogTimer;
    unsigned char WatchDogCount=0;
};

#endif // RECEIVE_H
