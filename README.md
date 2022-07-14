# Breitbandmessung.de Docker Container

```bash
docker run -d -v $PWD/breitbandmessung/data:/config/xdg/config/Breitbandmessung -p 5800:5800 --name breitband-desktop registry.fabianbees.de/fabianbees/breitbandmessung-docker:latest
```


## Automated Speedtesting

1. Open your browser with the fillowing url: http://ip-of-docker-host:5800


2. Go throgh setup process, until you reach the following page:
![Screenshot1](images/screenshot1.png)
**DO NOT KLICK THE BUTTON "Messung durchführen" if you want to use the Speedtest automation script!**

3. open a console (bash) to your docker container (```docker exec -it breitband-desktop bash```) and execute the following command inside this docker container:
```bash
touch /RUN
```
This creates a empty file called ```RUN``` in the root directory of the container, the automation script is looking for this file for knowing when the setup process has finished and speedtesting can start.

4. Speedtesting get's started, the script tries to click through the buttons for running a speedtest every 5 minutes. If the countdown timer (waiting period) has not finished yet, the cilcks will do nothing.

5. When all mesurements are done, the automation-script can be stopped by removing the ```/RUN``` file with the following command ```rm /RUN``` inside the docker container


