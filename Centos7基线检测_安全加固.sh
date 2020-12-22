#! /bin/bash

##############################################################################

#脚本运行前备份所有涉及到的文件，共12个

cp /etc/login.defs /etc/login.defs.bak

cp /etc/security/limits.conf /etc/security/limits.conf.bak

cp /etc/profile /etc/profile.bak

cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bak

cp /etc/inittab /etc/inittab.bak

cp /etc/motd /etc/motd.bak

cp /etc/group /etc/group.bak

cp /etc/shadow /etc/shadow.bak

cp /etc/services /etc/services.bak

cp /etc/passwd /etc/passwd.bak

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

cp /etc/aliases /etc/aliases.bak

#############################################################################


#1、------------检查是否有空口令账户-------------
echo "********************************************"
N=`awk -F: '($2==""){print $1}' /etc/shadow|wc -l`
echo "系统中空密码用户有：$N"
if [ $N -eq 0 ];then
 echo "恭喜你，系统中无空密码用户！！"
 echo "********************************************"
else
 i=1
 while [ $N -gt 0 ]
 do
    None=`awk -F: '($2==""){print $1}' /etc/shadow|awk 'NR=='$i'{print}'`
    echo "------------------------"
    echo $None
    echo "必须为空用户设置密码！！"
    passwd $None
    let N--
 done
 M=`awk -F: '($2==""){print $1}' /etc/shadow|wc -l`
 if [ $M -eq 0 ];then
  echo "恭喜，系统中已经没有空密码用户了！"
 else
echo "系统中还存在空密码用户：$M"
 fi
fi

echo -e '\n\n\n'

#2、---------------设置口令强度------------------
echo "已对密码进行加固，新用户不得和旧密码相同，且新密码必须同时包含数字、小写字母，大写字母！！"
echo "#-------------------------------------"
sed -i '/pam_pwquality.so/c\password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=  difok=1 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1' /etc/pam.d/system-auth


#3、---------------用户锁定策略------------------
echo "已对密码进行加固，如果输入错误密码超过10次，则锁定账户5min！！"
echo "#-------------------------------------"
sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/system-auth /etc/pam.d/password-auth
sed -ri "1a auth       required     pam_tally2.so deny=10 unlock_time=300 even_deny_root root_unlock_time=30" /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/system-auth /etc/pam.d/password-auth
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/sshd || sed -ri '/^password\s+.+(\s*#.*)?\s*$/i\account    required     pam_tally2.so' /etc/pam.d/sshd
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/login || sed -ri '/^password\s+.+(\s*#.*)?\s*$/i\account    required     pam_tally2.so' /etc/pam.d/login
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/system-auth || sed -ri '/^account\s+required\s+pam_permit.so\s*(\s*#.*)?\s*$/a\account     required      pam_tally2.so' /etc/pam.d/system-auth
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/password-auth || sed -ri '/^account\s+required\s+pam_permit.so\s*(\s*#.*)?\s*$/a\account     required      pam_tally2.so' /etc/pam.d/password-auth

echo -e '\n\n\n'

#4、--------检查是否存在除root之外UID为0的用户----------
#section2 限制root用户直接telnet或rlogin，ssh无效
######建议在/etc/securetty文件中配置：CONSOLE = /dev/tty01
#---------------------------------------------------------------------

echo -e '\n\n\n'

#5、-------------root用户远程登录限制-------------
#帐号与口令-检查是否存在除root之外UID为0的用户
echo "#检查系统中是否存在其它id为0的用户"
echo "#-------------------------------------"
mesg=`awk -F: '($3 == 0) { print $1 }' /etc/passwd|grep -v root`
if [ -z $mesg ]
then
echo "恭喜你，系统中没有ID为0的用户"
else
echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "$mesg uid=0"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

echo -e '\n\n\n'

#6、------- root用户环境变量的安全性------------------
echo "#确保root用户的系统路径中不包含父目录，在非必要的情况下，不应包含组权限为777的目录"
echo "#-------------------------------------"
echo $PATH | egrep '(^|:)(\.|:|$)'
find `echo $PATH | tr ':' ' '` -type d \( -perm -002 -o -perm -020 \) -ls

echo -e '\n\n\n'

#7、----------远程连接的安全性配置--------------------
echo "#检查操作系统Linux远程连接"
echo "#-------------------------------------"
find  / -name  .netrc
find  / -name  .rhosts

echo -e '\n\n\n'

#8、----------用户的umask安全检查--------------------
echo "#修复用户umask设置"
echo "#-------------------------------------"
ACTUAL=`umask`
policy=0027
if [ "$ACTUAL" != "$policy" ]
then
echo "umask 027" >>/etc/profile
echo "umask 027" >>/etc/bashrc
fi
source /etc/profile
source /etc/bashrc
umask 027
echo -e '\n\n\n'

#9、-------、重要目录和文件的权限设置---------------
echo "#修复重要目录或文件权限设置"
echo "#-------------------------------------"
echo "chmod 644 /etc/passwd"
echo "chmod 400 /etc/shadow"
echo "chmod 644 /etc/group"
echo "chmod -R 750 /etc/rc.d/init.d/*"
echo "chmod 664 /var/log/wtmp"
chmod 644 /etc/passwd
chmod 400 /etc/shadow
chmod 644 /etc/group
chmod -R 750 /etc/rc.d/init.d/*
#chmod 755 /bin/su 改了之后只能root su，没有了s位别的用户无法成功su
chmod 664 /var/log/wtmp
#chattr +a /var/log/messages

echo -e '\n\n\n'

#10、--------查找未授权的SUID/SGID文件-------------
echo "#查找系统中存在的SUID和SGID程序"
echo "#-------------------------------------"
find / -xdev -perm -04000 -o -perm -02000 |xargs ls  -l

echo -e '\n\n\n'

#11、-------检查任何人都有写权限的目录--------------------
echo "#查找系统中任何人都有写权限的目录"
echo "#-------------------------------------"
find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print  |xargs ls  -ld

echo -e '\n\n\n'

#12、--------检查任何人都有写权限的文件------------------
echo "#查找系统中任何人都有写权限的文件"
echo "#-------------------------------------"
find / -xdev -type f \( -perm -0002 -a ! -perm -1000 \) -print  |xargs ls  -l

echo -e '\n\n\n'

#13、-------查找系统中没有属主的文件--------------------
echo "#查找系统中没有属主的文件"
echo "#-------------------------------------"
find / -xdev \( -nouser -o -nogroup \) -print

echo -e '\n\n\n'

#14、--------查找系统中的隐藏文件-----------------------
###echo "#查找系统中的隐藏文件"
##echo "#-------------------------------------"
# find  / -name ".. *" -print -xdev
# find  / -name "…*" -print -xdev | cat -v


echo -e '\n\n\n'

#15、---------登录超时设置设置成600s---------------------------------
echo "#登录超时设置设置成600s"
echo "#-------------------------------------"
TMOUT=`cat /etc/profile | grep "export TMOUT="`
if [ -z "$TMOUT" ]
then
echo "export TMOUT=600" >>/etc/profile
else
sed -i 's/.*export TMOUT=.*/export TMOUT=600'/g /etc/profile
fi

echo -e '\n\n\n'

#16、--------禁用Telnet，启用SSH----------------------------------
echo "#禁用telnet启用ssh"
echo "#-------------------------------------"
mesg1=`lsof -i:23`
mesg2=`lsof -i:22`
if [ ! -n "$mesg2" ]
then
systemctl start sshd
chkconfig sshd on
mesg2=`lsof -i:22`
fi
if [ ! -n "$mesg1" -a ! -n "$mesg2" ]
then
echo
echo "Will Deactive telnet"
systemctl disable telnet
fi

echo -e '\n\n\n'

#17、--------对SSH服务进行安全检查----------------------------------
##使用命令“vi /etc/ssh/sshd_config”编辑配置文件
##（1）不允许root直接登录
##设置“PermitRootLogin ”的值为no
##（2）修改SSH使用的协议版本
##设置“Protocol”的版本为2

#18、--------关闭不必要的服务----------------------------------
echo "#禁用不必要的服务"
echo "#-------------------------------------"
list="bluetooth cups cpuspeed firstboot netfs nfslock postfix"
for i in $list
do
systemctl disable $i
systemctl stop $i
done
####echo "change kernel parameter for network secure"（默认注释掉了）
#cp  /etc/sysctl.conf /etc/sysctl.conf.$date
#echo "net.ipv4.icmp_echo_ignore_all = 1">>/etc/sysctl.conf
#sysctl -a |grep arp_filter|sed -e 's/\=\ 0/\=\ 1/g' >>/etc/sysctl.conf
#sysctl -a |grep accept_redirects|sed -e 's/\=\ 1/\=\ 0/g' >>/etc/sysctl.conf
#sysctl -a |grep send_redirects|sed -e 's/\=\ 1/\=\ 0/g' >>/etc/sysctl.conf
#sysctl -a |grep log_martians |sed -e 's/\=\ 0/\=\ 1/g'>>/etc/sysctl.conf
#sysctl -p

echo -e '\n\n\n'

#19、-------日志审计---------------------------------------------
echo "#判断日志与审计是否合规"
echo "#-------------------------------------"
echo "使用cat /etc/rsyslog.conf |egrep ^authpriv查看是否有该参数"
cat /etc/rsyslog.conf |egrep ^authpriv


echo -e '\n\n\n'

#20、-----系统core dump修复----------------------------------
echo "系统core dump修复"
echo "#-------------------------------------"
HARD=`cat /etc/security/limits.conf | grep "hard core"`
if [ -z "$HARD" ]
then
echo "* hard core 0" >>/etc/security/limits.conf
else
sed -i 's/.*hard core.*/* hard core 0'/g /etc/security/limits.conf
fi
SOFT=`cat /etc/security/limits.conf | grep "soft core"`
if [ -z "$SOFT" ]
then
echo "* soft core 0" >>/etc/security/limits.conf
else
sed -i 's/.*soft core.*/* soft core 0'/g /etc/security/limits.conf
fi
