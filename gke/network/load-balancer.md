# Деякі налаштування і політики LoadBalancer

## kube-proxy завжди вибиратиме Pod на вузлі-одержувачі (знижує затримку, але можуть виникнути проблеми з рівномірним навантаженням):
```yaml
spec:
  type: LoadBalancer
    ExternalTrafficPolicy: Local
```
