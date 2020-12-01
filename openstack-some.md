# openstack aio 试验

---

github下载慢问题
github加速 https://www.cnblogs.com/pogyang/p/13797430.html
https://hub.fastgit.org
199.232.69.194 github.global.ssl.fastly.net
140.82.114.3 github.com

find ./ -type f|xargs sed -i 's/opendev.org/hub.fastgit.org/g'
find ./ -type f|xargs sed -i 's/github.com/hub.fastgit.org/g'
/etc/ansible/roles/lxc_hosts/vars/redhat-7.yml
  _lxc_hosts_container_image_url: "http://artifacts.ci.centos.org/sig-cloudinstance/centos-7-191001/x86_64/centos-7-x86_64-docker.tar.xz"  手动下，修改地址
  
  
---------------------

# kolla-ansible

https://www.cnblogs.com/omgasw/p/12054726.html
https://wiki.openstack.org/wiki/Kolla
https://docs.openstack.org/kolla-ansible/latest/
https://docs.openstack.org/kolla-ansible/latest/user/quickstart.html
https://docs.openstack.org//kolla-ansible/latest/doc-kolla-ansible.pdf

https://www.jianshu.com/p/73598a5cd00b
https://www.jianshu.com/p/f02f358a79f4

https://www.cnblogs.com/omgasw/p/13719701.html
https://blog.csdn.net/Doudou_Mylove/article/details/105195007
