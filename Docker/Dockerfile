FROM kasmweb/core-ubuntu-focal:1.14.0
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########

RUN  wget https://www.termius.com/download/linux/Termius.deb \
    && apt-get update \
    && apt-get install -y apt-transport-https \
    && apt install -y libgtk-3-0 libnotify4 libxss1 libxtst6 xdg-utils libatspi2.0-0 libsecret-1-0 \
    && dpkg -i Termius.deb    && cp /usr/share/applications/termius-app.desktop $HOME/Desktop/ \
    && chmod +x $HOME/Desktop/termius-app.desktop \
    && chown 1000:1000 $HOME/Desktop/termius-app.desktop

RUN echo "/usr/bin/desktop_ready && /Termius/termius-app --no-sandbox &" > $STARTUPDIR/custom_startup.sh \
&& chmod +x $STARTUPDIR/custom_startup.sh

######### End Customizations ###########

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000