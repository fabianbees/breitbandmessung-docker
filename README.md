# Breitbandmessung.de Docker Container



## Building the Container

First you have to build the docker container localy, due to licencing I will not provide a prebuild image of the app.

You can do this with the following commands:

```bash
git clone https://gitlab.fabianbees.de/fabianbees/breitbandmessung-docker.git

cd breitbandmessung-docker

docker build -t breitband:latest .
```

## Run the Container

Then the container can be run:

```bash
docker run -d -v $PWD/breitbandmessung/data:/config/xdg/config/Breitbandmessung -p 5800:5800 --name breitband-desktop breitband:latest
```

Appdata for the Breitbandmessung Desktop App lives in the following directory (inside the container): ```/config/xdg/config/Breitbandmessung```. Therefore this directory can be mounted to a host directory.


## Automated Speedtesting

1. Open your browser with the following url: http://ip-of-docker-host:5800


2. Go throgh setup process, until you reach the following page:
![Screenshot1](images/screenshot1.png)
**DO NOT KLICK THE BUTTON "Messung durchführen" if you want to use the Speedtest automation script!**
--> The automation script requires this exact screen to be shown for the automatic execution of a "Messkampagne".

3. open a console (bash) to your docker container (```docker exec -it breitband-desktop bash```) and execute the following command inside this docker container:
```bash
touch /RUN
```
This creates a empty file called ```RUN``` in the root directory of the container, the automation script is looking for this file for knowing when the setup process has finished and speedtesting can start.

4. Speedtesting get's started, the script tries to click through the buttons for running a speedtest every 5 minutes. If the countdown timer (waiting period) has not finished yet, the cilcks will do nothing.

5. When all mesurements are done, the automation-script can be stopped by removing the ```/RUN``` file with the following command ```rm /RUN``` inside the docker container


