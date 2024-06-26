FROM node:18
RUN apt update && \
    apt install git -y && \
    mkdir /root/strapi
WORKDIR /root/strapi
COPY . .
RUN npm install
RUN npm install pm2 -g
EXPOSE 1337
CMD ["pm2-runtime", "start", "npm", "--", "run", "start"]

