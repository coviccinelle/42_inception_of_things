## Requirements

```bash
export VAGRANT_HOME=~/goinfre/.vagrant.d
```

## Then vagrant up

```bash
cd p2
vagrant up
```

## Shh to verify

```bash
vagrant ssh thi-phngS
```

## check pods and ingress

```bash
kubectl get all
kubectl get ingress
```

## Test routing

```bash
curl -H "Host: app1.com" http://192.168.56.110 # -> Hello from app1
curl -H "Host: app2.com" http://192.168.56.110 # -> Hello from app2
curl -H http://192.168.56.110                  # -> Hello from app3
```

## Expected results
```bash
<h1>Hello from app1.</h1>
<h1>Hello from app2.</h1>
<h1>Hello from app3.</h1>
```


## Workflow
curl -H "Host: app1.com" http://192.168.56.110
         │
         ▼
    Traefik (Ingress Controller)
         │
         │ compare Host header with rules
         │
         ├── Host == "app1.com"  →  Service app-one   →  Pod app-one
         ├── Host == "app2.com"  →  Service app-two   →  Pod app-two (×3)
         └── Host == (others)      →  Service app-three →  Pod app-three

Done part 2
