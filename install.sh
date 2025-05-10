#!/bin/bash

# Funzione per l'installazione del Pterodactyl Panel
install_panel() {
    echo "🚀 Avvio dell'installazione di Pterodactyl Panel..."
    
    # Aggiornamento sistema
    sudo apt update && sudo apt upgrade -y
    
    # Installazione delle dipendenze
    sudo apt install -y curl wget unzip sudo software-properties-common
    
    # Aggiungi i repository richiesti
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt update

    # Installazione di PHP 8.1
    sudo apt install -y php8.1 php8.1-cli php8.1-fpm php8.1-mbstring php8.1-xml php8.1-mysql php8.1-curl php8.1-bcmath php8.1-json php8.1-zip php8.1-soap php8.1-opcache

    # Installazione di Nginx e MariaDB
    sudo apt install -y nginx mariadb-server

    # Installazione di Composer
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    
    # Creazione del database per Pterodactyl
    sudo mysql -e "CREATE DATABASE pterodactyl;"
    sudo mysql -e "CREATE USER 'pterodactyl'@'localhost' IDENTIFIED BY 'password';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON pterodactyl.* TO 'pterodactyl'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    # Scaricare e configurare il Pterodactyl Panel
    cd /var/www
    sudo wget https://github.com/pterodactyl/panel/releases/download/v1.0.0/panel.tar.gz
    sudo tar -xzvf panel.tar.gz
    sudo chown -R www-data:www-data /var/www/pterodactyl

    # Configurazione del Pterodactyl Panel
    cd /var/www/pterodactyl
    sudo cp .env.example .env
    sudo php artisan key:generate
    sudo php artisan p:environment:setup
    sudo php artisan p:environment:database
    sudo php artisan migrate --seed --force
    sudo php artisan p:install

    # Configurazione di Nginx
    sudo cp /var/www/pterodactyl/nginx/pterodactyl.conf /etc/nginx/sites-available/pterodactyl
    sudo ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
    sudo systemctl restart nginx

    echo "🎉 Pterodactyl Panel è stato installato con successo!"
}

# Funzione per l'installazione di Wings
install_wings() {
    echo "🚀 Avvio dell'installazione di Wings..."

    # Download di Wings
    wget https://github.com/pterodactyl/wings/releases/latest/download/wings-linux-amd64.tar.gz
    tar -xvzf wings-linux-amd64.tar.gz
    sudo mv wings /usr/local/bin/wings

    # Configurazione di Wings
    sudo wings --config /etc/pterodactyl/wings/config.yml

    # Avvio di Wings
    sudo systemctl enable wings
    sudo systemctl start wings

    echo "🎉 Wings è stato installato con successo!"
}

# Funzione per disinstallare Pterodactyl Panel
uninstall_panel() {
    echo "🚨 Rimozione di Pterodactyl Panel..."
    
    # Rimuove Nginx, MariaDB e le dipendenze
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    sudo apt purge --auto-remove nginx mariadb-server php8.1* -y
    
    # Rimuove Pterodactyl Panel
    sudo rm -rf /var/www/pterodactyl
    sudo rm /etc/nginx/sites-available/pterodactyl
    sudo rm /etc/nginx/sites-enabled/pterodactyl
    
    echo "❌ Pterodactyl Panel è stato rimosso con successo!"
}

# Funzione per disinstallare Wings
uninstall_wings() {
    echo "🚨 Rimozione di Wings..."
    
    # Rimuove Wings
    sudo systemctl stop wings
    sudo systemctl disable wings
    sudo rm /usr/local/bin/wings
    sudo rm -rf /etc/pterodactyl/wings
    
    echo "❌ Wings è stato rimosso con successo!"
}

# Menu di opzioni
echo "👋 Benvenuto nello script di installazione Pterodactyl!"
echo "Scegli un'opzione:"
echo "1) Installare Pterodactyl Panel e Wings"
echo "2) Disinstallare Pterodactyl Panel"
echo "3) Disinstallare Wings"
read -p "Scegli un'opzione (1, 2, 3): " scelta

case $scelta in
    1)
        echo "🎉 Iniziamo con l'installazione di Pterodactyl Panel e Wings..."
        install_panel
        read -p "Desideri installare anche Wings? (s/n): " wings_scelta
        if [[ "$wings_scelta" == "s" || "$wings_scelta" == "S" ]]; then
            install_wings
        else
            echo "Wings non è stato installato."
        fi
        ;;
    2)
        uninstall_panel
        ;;
    3)
        uninstall_wings
        ;;
    *)
        echo "⚠️ Scelta non valida, esco..."
        ;;
esac
