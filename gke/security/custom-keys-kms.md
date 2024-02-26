# Використання керованих клієнтом ключів шифрування з Cloud Storage та Cloud KMS

## Створення ключів в Cloud KMS

1) Виконайте таку команду, щоб створити bucket:

```sh
gsutil mb -l us gs://$DEVSHELL_PROJECT_ID-kms
```

2) У Cloud Shell виконайте такі команди, щоб створити змінні для зберігання імені KeyRing і імені CryptoKey:

```sh
KEYRING_NAME=lab-keyring
CRYPTOKEY_1_NAME=labkey-1
CRYPTOKEY_2_NAME=labkey-2
```

3) Виконайте наступну команду, щоб створити KeyRing.

```sh
gcloud kms keyrings create $KEYRING_NAME --location us
```

4) Далі, використовуючи новий KeyRing, створіть CryptoKey під назвою labkey-1 :

```sh
gcloud kms keys create $CRYPTOKEY_1_NAME --location us \
--keyring $KEYRING_NAME --purpose encryption
```

5) Створіть інший CryptoKey під назвою labkey-2 :

```sh
gcloud kms keys create $CRYPTOKEY_2_NAME --location us \
--keyring $KEYRING_NAME --purpose encryption
```

## Додайте ключ за замовчуванням для bucket

1) Виконайте таку команду, щоб переглянути ключ шифрування за умовчанням для bucket:

```sh
gsutil kms encryption gs://$DEVSHELL_PROJECT_ID-kms
```

2) Виконайте такі команди, щоб надати обліковому запису служби Cloud Storage дозвіл на використання обох ваших ключів Cloud KMS:

```sh
gsutil kms authorize -p $DEVSHELL_PROJECT_ID -k \
projects/$DEVSHELL_PROJECT_ID/locations/us/keyRings\
/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_1_NAME
gsutil kms authorize -p $DEVSHELL_PROJECT_ID -k \
projects/$DEVSHELL_PROJECT_ID/locations/us/keyRings\
/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_2_NAME
```

3) Виконайте таку команду, щоб установити ключ за замовчуванням для bucket на перший ключ, який ви згенерували:

```sh
gsutil kms encryption -k \
projects/$DEVSHELL_PROJECT_ID/locations/us/keyRings\
/$KEYRING_NAME/cryptoKeys/$CRYPTOKEY_1_NAME \
gs://$DEVSHELL_PROJECT_ID-kms
```

4) Виконайте таку команду, щоб переглянути ключ за замовчуванням для сегмента, щоб переконатися, що остання команда виконана успішно:

```sh
gsutil kms encryption gs://$DEVSHELL_PROJECT_ID-kms
```
