# fpm-dev

Debian image installed with AWS utilities, git, ssh, php, fpm, xdebug, etc. Designed and used mostly for WordPress and WooCommerce development in a docker-compose group. 

## Paths
The nginx paths and fpm-dev paths start the application from the /code folder in this example. Changes to that location would need to be made in each docker container and in the XDebug config.

Sample docker-compose.yaml

```yaml
version: '3.3'

services:
  db:
    image: mariadb:10.5.4
    ports:
      - '3306:3306'
    volumes:
      - fpm_dev_data_maria:/var/lib/mysql
    restart: always
    env_file: .env
    networks:
      - wpsite

  phpmyadmin:
    depends_on:
      - db
    image: phpmyadmin/phpmyadmin
    restart: always
    ports:
      - '8000:80'
    env_file: .env
    networks:
      - wpsite

  web: 
    depends_on: 
      - fpm-dev
    image: nginx:latest
    ports: 
      - "80:80"
      - "443:443"
    env_file: .env
    volumes:
      - /path/to/wp/root:/code
      - ./conf/site.conf:/etc/nginx/conf.d/default.conf
      - ./conf/nginx/ssl:/etc/nginx/ssl
    networks:
      - wpsite

  fpm-dev:
    image: mage7223/fpm-dev:latest
    depends_on: 
      - db
    container_name: fpm-dev
    env_file: .env
    volumes:
      - /path/to/wp/root:/code
      - ~/.ssh:/var/www/.ssh
      - ~/.aws:/var/www/.aws
    networks:
      - wpsite

networks:
  wpsite:
    driver: bridge
volumes:
    fpm_dev_data_maria:
    fpm_dev_web_app:
```

## AWS Utilities

AWS utilities are made available in the fpm-dev image but rely on a share to read the AWS credentials and settings. The default location for these files are in the ~/.aws/ folder. More info in the [AWS Configuration and Credential File Settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html). You will need to add the ~/.aws/credentials file to the docker-compose if required, profiles are partially supported.

## XDebug
Setting up XDebug is not difficult. The fpm-dev container is already configured to use the xdebug libraries and connect to the proper port on the docker host machine via IPv4. Since the XDebug host is the machine that originates the connection, the development environment on the host machine needs to be set up to handle connections. VSCode will need to be configured to handle the connection originating from the docker container and that is dune with a Run Configuration. This requires an XDebug extension to be running in the VSCode environment. I suggest felixfbecker.php-debug extension.

Here is a quick article to perform a quick setup or copy this to your project folder/.vscode/launch.json
```json
{
    "version": "0.2.0",
    "configurations": [
      {
        "name": "Listen for XDebug (launch)",
        "type": "php",
        "request": "launch",
        "hostname":"0.0.0.0",
        "port": 9000,
        "pathMappings": {
          "/code": "${workspaceFolder}"
        },
        "xdebugSettings": {
          "max_data": 65535,
          "show_hidden": 1,
          "max_children": 100,
          "max_depth": 5
        }
      }
    ]
  }
```

## Nginx Config
Nginx config needs to be done and is beyond the scope of this container but here is what I mount and use
```nginx
server {
    listen 80;

    listen 443 ssl http2;

    ssl_certificate /etc/nginx/ssl/cert.pem; 
    ssl_certificate_key /etc/nginx/ssl/cert.pem; 

    index index.php index.html;
    server_name localhost;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /code;

    location / {
        try_files $uri $uri/ =404
    	try_files $uri $uri/ /index.php$is_args$args;
    }


    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass fpm-dev:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

It's usually a good idea to add a file called info.php with the following contents to check the debug and other settings
```php
<?php
phpinfo();
```

## Git & SSH 
Git is installed in the docker image along with an ssh client. 

 