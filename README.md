## Apigee Drupal8 Developer Portal Kickstart

This repo contains a Dockerfile for building the an container image with the following components:

* [Apache 2](https://httpd.apache.org/)
* [MariaDB 10](https://mariadb.com/)
* [Apigee Drupal8 Kickstart](https://www.drupal.org/project/apigee_devportal_kickstart)

The docker image is meant to be used for development or demonstration purposes.

![](images/kickstart.png?raw=true "Apigee Developer Portal Kickstart")


### Usage

In order to use the docker image, run the following command:

```bash
 docker run --rm -it \
            --publish 8080:80 \
            --name dev-portal \
            micovery/apigee-drupal8-dev-portal:latest
```

Then, point your browser to http://localhost:8080

The default administrator credentials are:

```
username: admin@localhost
password: admin
``` 


### Inside the container

You an go into a bash shell inside the container by running the following command:

```bash
 docker exec -it dev-portal bash
```

This will log you in as the `drupal` user. The Drupal installation is located in /drupal/project.

From the shell you can use `composer` to install Drupal modules, and `drush` to enable them.


### Build Prerequisites

  * bash (Linux shell)
  * [Docker (18 or newer)](https://www.docker.com/)
  

### Building it


If you want to build the docker image yourself, run.


```bash
$ KICKSTART_VERSION=8.x-dev ./build.sh
```

Check the official project page for the [Apigee Developer Portal Kickstart](https://www.drupal.org/project/apigee_devportal_kickstart) to see full list of versions.

### Not Google Product Clause

This is not an officially supported Google product.