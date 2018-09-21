FROM golang:1.11.0

ADD . /app
WORKDIR /app

ENV CGO_ENABLED=0
ENV GOOS=linux 

RUN go build -mod vendor -o setup-pipelines .

FROM alpine:latest
RUN apk --no-cache add ca-certificates jq
COPY --from=0 /app/setup-pipelines /usr/local/bin/setup-pipelines
CMD ["/usr/local/bin/setup-pipelines"]
