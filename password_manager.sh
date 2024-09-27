#!/bin/bash

set -eu -o pipefail

# Add Passwordが選ばれたときに行う処理
function ask_passwd () {
    local servie_name
    echo -n "サービス名を入力してください："
    while true ; do
        read service_name
        local validator=$(echo "$service_name" | grep ":")
        if [ "$validator" != "" ] ; then
            echo -n "':'を使用することはできません。再度サービス名を入力してください："
        elif [ "$service_name" != "" ] ; then
            break
        fi
    done
    local user_name
    echo -n "ユーザー名を入力してください："
    while true ; do
        read user_name
        local validator=$(echo "$user_name" | grep ":")
        local registration_verification=`grep "$service_name"":""$user_name" ./save_location`
        if [ "$validator" != "" ] ; then
            echo -n "':'を使用することはできません。再度ユーザー名を入力してください："
        elif [ "$registration_verification" == "" ] ; then
            break
        else
            echo -n "そのサービス名とユーザー名の組み合わせは既に登録されています。別ユーザー名を入力してください："
        fi
    done

    local password
    echo -n "パスワードを入力してください："
    while true ; do
        read password
        local validator=$(echo "$password" | grep ":")
        if [ "$validator" != "" ] ; then
            echo -n "':'を使用することはできません。パスワードを入力してください："
        else
            break
        fi
    done

    echo "Thank you!"
    echo $service_name":"$user_name":"$password >> ./save_location
}

# Get Passwordが選ばれたときに行う処理
function provide_password () {
    local service_name
    # サービス名を取得する
    while true ; do
        read -p "サービス名を入力してください:" service_name
        if [ "$service_name" != "" ] ; then
            break
        fi
    done

    local target=`grep "$service_name" ./save_location`
    target=$(echo "$target" | awk -F':' -v service_name="$service_name" '$1 == service_name')
    echo "てすと""$target"
    local hitNumber=$(echo "$target" | grep -c "$service_name")

    # hitした登録情報の数によって処理を分ける。2つ以上hitした場合はユーザー名でさらに条件を絞る。
    if [ "$hitNumber" -eq 0 ] ; then
        echo "そのサービス名は登録されていません"
    # 1つ以上の登録があった場合
    else
        # 2つ以上の登録があった場合さらに条件を絞る
        if [ "$hitNumber" -gt 1 ] ; then
            # hitした登録のユーザー名を取得する
            local acounts=$(echo "$target" | awk -F':' '{print $2}')
            local acount_name
            local target_line

            echo "そのサービス名は複数登録されています。下記の中からユーザー名を入力してください。"
            while true ; do
                echo "$acounts"
                read -p "：" acount_name
                target_line=$(echo "$target" | awk -F':' -v acount_name="$acount_name" '$2 == acount_name')

                if [ "$target_line" != "" ] ; then
                    target="$target_line"
                    break
                else
                    echo "入力が間違っています。下記の中からユーザー名を入力してください。"
                fi
            done
        fi
        echo "サービス名："${target%%:*}
        echo "ユーザー名："$(echo "$target" | awk -F':' '{print $2}')
        echo "パスワード："${target##*:}
    fi
}

# このスクリプトの全体の流れを制御する
echo パスワードマネージャーへようこそ！

while true ; do
    echo -n "次の選択肢から入力してください(Add Password/Get Password/Exit)："
    while true ; do
        read choice
        if [ "$choice" == "Add Password" ] ; then
            ask_passwd
            break
        elif [ "$choice" == "Get Password" ] ; then
            provide_password
            break
        elif [ "$choice" == "Exit" ] ; then
            echo "Thank you!"
            exit 0
        else
            echo "入力が間違えています。Add Password/Get Password/Exit から入力してください。"
        fi
    done
done