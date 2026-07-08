FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/
COPY config.js /usr/share/nginx/html/
COPY logo-orcamentos.png /usr/share/nginx/html/
EXPOSE 80
