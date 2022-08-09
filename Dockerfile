# syntax=docker/dockerfile:1

FROM golang:1.19.0-alpine3.15

WORKDIR /app
COPY . .
RUN go build -o main . 

#COPY go.mod ./
#COPY go.sum ./
#RUN go mod download
#COPY * ./
#RUN go build . /docker-getwea

EXPOSE 8080

CMD [ "/app/main" ]