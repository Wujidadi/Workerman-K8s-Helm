FROM wujidadi/ubuntu-tuned:20250315

ARG php_version=8.4

RUN echo "\033[38;2;255;215;0m更新 apt 套件庫 ...\033[0m" && \
    apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get upgrade -y; \
    apt-get install -y --no-install-recommends software-properties-common; \
    echo "" && \
    echo "\033[38;2;255;215;0m安裝 PHP ...\033[0m" && \
    add-apt-repository -y ppa:ondrej/php;\
    apt-get update && apt-get upgrade -y;\
    apt-get install -y --no-install-recommends php${php_version} php${php_version}-cli php${php_version}-common php${php_version}-fpm php${php_version}-raphf php${php_version}-http php${php_version}-xdebug php-pear php${php_version}-curl php${php_version}-dev php${php_version}-gd php${php_version}-mbstring php${php_version}-zip php${php_version}-mysql php${php_version}-opcache php${php_version}-readline php${php_version}-xml php${php_version}-tidy php${php_version}-imagick php${php_version}-gmp php${php_version}-bz2 php${php_version}-soap php${php_version}-bcmath php${php_version}-intl php${php_version}-igbinary php${php_version}-pgsql php${php_version}-sqlite3 odbc-postgresql;\
    echo "" && \
    echo "\033[38;2;255;215;0m安裝 PHP Event 擴展 (必須比 Socket 擴展晚載入)\033[0m" && \
    pecl channel-update pecl.php.net;\
    apt-get install -y libevent-dev;\
    sh -c '/bin/echo "no" | pecl install event';\
    echo "extension=event.so" | sudo tee /etc/php/${php_version}/mods-available/event.ini;\
    phpenmod event;\
    mv /etc/php/${php_version}/cli/conf.d/20-event.ini /etc/php/${php_version}/cli/conf.d/30-event.ini;\
    mv /etc/php/${php_version}/fpm/conf.d/20-event.ini /etc/php/${php_version}/fpm/conf.d/30-event.ini;\
    echo "" && \
    echo "\033[38;2;255;215;0m安裝 Composer\033[0m" && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');";\
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }";\
    php composer-setup.php;\
    php -r "unlink('composer-setup.php');";\
    mv composer.phar /usr/local/bin/composer;\
    echo "" && \
    echo "\033[38;2;255;215;0m安裝 PostgreSQL client\033[0m" && \
    apt-get install -y postgresql-client && \
    echo "" && \
    echo "\033[38;2;255;215;0m清理 apt 套件庫\033[0m" && \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    echo "" && \
    echo "\033[38;2;255;215;0m更改預設文字編輯器為 Vim\033[0m" && \
    echo 'export EDITOR=vim' >> /root/.zshrc; \
    echo "" && \
    echo "\033[38;2;255;215;0m建立自訂應用程式目錄\033[0m" && \
    mkdir /app;\
    echo "" && \
    echo "\033[38;2;255;215;0m建立 Zsh 歷史紀錄目錄\033[0m" && \
    touch /root/.zsh_history
