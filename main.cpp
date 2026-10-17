#include "mainwindow.h"
#include <QApplication>
#include <QMetaType> // CRITICAL HEADER

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    // Update your meta-type registry definition to link to the new QString path
    qRegisterMetaType<QString>("QString");

    MainWindow w;
    w.show();
    return a.exec();
}
