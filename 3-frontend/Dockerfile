FROM nginx:alpine

COPY src/index.html /usr/share/nginx/html/
COPY src/css/ /usr/share/nginx/html/css/
COPY src/js/ /usr/share/nginx/html/js/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
