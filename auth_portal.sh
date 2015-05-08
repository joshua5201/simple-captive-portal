#!/bin/bash

bash /root/iptables.sh  # restore rules

auth_pipe=/tmp/captive_auth
res_pipe=/tmp/captive_res

user=joshua5201
group=joshua5201
extif=enp0s3

trap "rm -f $auth_pipe $res_pipe" EXIT
if [[ ! -p $auth_pipe ]]; then
    mkfifo $auth_pipe
    chown $user:$group $auth_pipe
fi
if [[ ! -p $res_pipe ]]; then
    mkfifo $res_pipe
    chown $user:$group $res_pipe
fi

passwd_file=portal.passwd
while true
do
    if read line < $auth_pipe ; then
        authuser=`echo "$line" | awk 'BEGIN {FS=";"}{print $1}'`
        authpasswd=`echo "$line" | awk 'BEGIN {FS=";"}{print $2}'`
        authipaddr=`echo "$line" | awk 'BEGIN {FS=";"}{print $3}'`
        authtime=`echo "$line" | awk 'BEGIN {FS=";"}{print $4}'`
    
        echo "Auth from $authipaddr $authtime"
        echo "username: $authuser"
        echo "passwd: $authpasswd"

        passed=false
        while read authdata
        do
            if [[ "$authuser;$authpasswd" == "$authdata" ]]; then
                echo "passed" > $res_pipe
                #requirement of NA course (redirecting to proxy)
                iptables -t nat -I PREROUTING 1 -s $authipaddr -p tcp --dport 80 -j REDIRECT --to-ports 3128                  
                #iptables -t nat -I PREROUTING 1 -s $authipaddr -p tcp --dport 80 -j ACCEPT 
                iptables -t filter -I FORWARD 1 -s $authipaddr -p tcp --dport 443 -j ACCEPT
                iptables -t nat -I POSTROUTING 1 -o $extif -j MASQUERADE
                passed=true
                echo "auth passed"
                break
            fi
            sleep 1
        done < "$passwd_file"
        if [[ "$passed" == "false" ]]; then
            echo "failed\n" > $res_pipe
            echo "auth failed"
        fi
    fi
    sleep 1
done
