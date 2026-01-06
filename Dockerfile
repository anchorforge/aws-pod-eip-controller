ARG GOLANG_VERSION=1.25.3
FROM public.ecr.aws/docker/library/golang:${GOLANG_VERSION} AS builder

WORKDIR /workspace
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    GOPROXY=direct go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build

ARG ALPINE_VERSION=3.22.2
FROM public.ecr.aws/docker/library/alpine:${ALPINE_VERSION}

ENV USER=eipcontroller
ENV GROUPNAME=$USER
ENV UID=5000
ENV GID=5000

COPY --from=builder /workspace/aws-pod-eip-controller /usr/local/bin/aws-pod-eip-controller

RUN addgroup \
    --gid "$GID" \
    "$GROUPNAME" \
&&  adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$GROUPNAME" \
    --no-create-home \
    --uid "$UID" \
    $USER

USER $UID

CMD ["aws-pod-eip-controller"]
