#!/bin/bash
###############################
#     系统状况分析脚本        #
#                             #
#用途：对系统CPU使用率、内存、#
#网络连接、磁盘空间、系统进程 #
#交易数量以及交易日志进行分析 #
#适用操作系统：Linux          #
#版本：1.0                    #
#                             #
###############################

#-----设置文件参数-----------------

FTPip=192.168.0.100
FTPuser=
FTPpasswd=
FTPdir=

#----设置系统名称
SYSNAME="民生村镇验印测试系统"


#-----日期变量--------
DATE=`date +%Y%m%d_%H%M`

#------日志文件存放地点，请根据系统目录进行修改-------
#logfile=/root/checklog/tmp/chksts.log.$YESTERDAY
#logfile=/root/checklog/tmp/chksts_JZTH_122.log.$Date2
MYLOGPATH=`pwd`
logfile=$MYLOGPATH/chk_linux_$DATE.log

#-----检查系统时间-----------------
date +%Y-%m-%d> $logfile

#####################################################
#####################################################

chksysname(){
#-----系统名称------------
echo -e "\n系统名称：$SYSNAME" >> $logfile
}
chksysversion(){
#-----操作系统版本--------
echo -e "\n操作系统版本" >> $logfile
lsb_release -a  >> $logfile
}
chkip(){
#-----系统ip地址----------------
echo -e "\n系统ip地址："`ifconfig eth0 |grep 'inet addr' |awk '{print $2}' |awk  -F  ":"  '{print $2}'` >> $logfile
}
chkcpu(){
#-------检查系统CPU使用率--------
echo -e "\n--------------系统CPU使用率检查-------------- " >> $logfile
vmstat | awk 'BEGIN {print "用户CPU使用率  系统CPU使用率  系统空闲CPU率"} {if($14>=0&&$14<100) printf"     %s               %s             %s\n",$13,$14,$15}' >>$logfile
}
chkmem(){
#------检查系统内存使用率-------
echo -e "\n-------------系统内存使用率检查-------------" >> $logfile
vmstat | awk 'BEGIN {print "系统使用内存页   系统空闲内存页 "} {if($4>=0&&$4<100000000) printf"   %s           %s\n",$4,$6}' >> $logfile
}
chkdf(){
#-----检查文件系统空间---------
echo -e "\n--------------文件空间检查-------------- " >> $logfile
#df -k  | awk 'BEGIN  {print "文件系统名称                 使用率"}  {if($4>=0&&$4<1000000000000) printf"%-20.20s   %10.10s\n", $6,$5}'  >> $logfile
df -h >> $logfile
}
chknetstat(){
#-----检查网络连接---------
echo -e "\n--------------网络连接检查-------------- " >> $logfile
netstat -an | grep 'LISTEN\>'>> $logfile
}
chkjava(){
#-----检查系统进程----------
echo -e "\n-------------java进程检查--------------\n" >> $logfile
ps -ef| grep java >> $logfile
}
chksrv(){
#-----交行影像提回系统服务器检查---------------
echo -e "\n-------------srv进程检查--------------\n" >> $logfile
ps -ef| grep srv >> $logfile
}
chkmysql(){
echo -e "\n-------------mysql进程检查--------------\n" >> $logfile
ps -ef| grep mysql >> $logfile
service mysqld status  >> $logfile
}
chkoracle(){
#-----检查oracle状态----------
echo -e "\n-------------oracle状态检查--------------\n" >> $logfile
su - oracle -c "lsnrctl status" >> $logfile

#------ORACLE监听文件检查-------
echo -e "\n--------------listener.ora 文件检测------\n" >> $logfile
ORACLE_HOME=`su - oracle -c env |grep ORACLE_HOME |awk -F "=" '{print $2}'`
LISTENER=$ORACLE_HOME/network/admin/listener.ora

#echo $ORACLE_HOME >> $logfile
if [ -f $LISTENER ];then
	cat $LISTENER >> $logfile
else
	echo -e "\nlistener.ora 文件检测失败\n"  >> $logfile
fi
}
chkhosts(){
echo -e "\n--------------hosts 文件检测--------------\n" >> $logfile
cat  /etc/hosts  >> $logfile
}

toftp(){
#----传输日志文件----------
/usr/bin/ftp -in $FTPip <<!
user $FTPuser $FTPpasswd
cd $FTPdir
put $logfile
bye
!
}

####请将不需要的检查项注释掉###
chksysname   #系统名称检查
chksysversion  #操作系统版本检查
chkip		#操作系统ip检查
chkcpu		#操作系统cpu使用率检查
chkmem		#内存使用率检查
chkdf		#磁盘使用率检查
chknetstat	#网络连接检查
chkjava		#java进程检查
#chksrv		#srv进程检查
chkmysql	#mysql进程检查
chkoracle	#oracle状态检查
chkhosts	#host文件检查
#toftp		 #将日志发送到FTP
echo -e "检查完毕"
echo -e "日志文件路径为:$logfile"
