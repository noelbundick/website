FROM alpine as build

ENV HUGO_VERSION 0.36
ENV HUGO_BINARY hugo_${HUGO_VERSION}_linux-64bit
ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY}.tar.gz /usr/local/hugo/
RUN tar xzf /usr/local/hugo/${HUGO_BINARY}.tar.gz -C /usr/local/hugo/ \
	&& ln -s /usr/local/hugo/hugo /usr/local/bin/hugo \
	&& rm /usr/local/hugo/${HUGO_BINARY}.tar.gz

COPY /site /site
WORKDIR /site
RUN hugo

FROM nginx:1.13.8-alpine

# Enable SSH with a hard-coded password
# - https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-ssh-support
RUN apk add --no-cache openssh \
  && ssh-keygen -A \
  && echo "root:Docker!" | chpasswd

COPY nginx.conf /etc/nginx/nginx.conf
COPY sshd_config /etc/ssh/
COPY init_container.sh /
RUN chmod +x /init_container.sh
CMD ["/init_container.sh"]

EXPOSE 80 2222

COPY --from=build /site/public /usr/share/nginx/html