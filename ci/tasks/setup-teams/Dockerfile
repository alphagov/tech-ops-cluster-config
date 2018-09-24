FROM golang:1.11.0

ADD . /app
WORKDIR /app

ENV CGO_ENABLED=0
ENV GOOS=linux 

RUN go build -mod vendor -o setup-teams .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=0 /app/setup-teams /usr/local/bin/setup-teams
CMD ["/usr/local/bin/setup-teams"]
