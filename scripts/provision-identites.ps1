# Reconstruit les identités du laboratoire : utilisateurs, groupes, politique et profils CLI.
# Prérequis : LocalStack démarré avec ENFORCE_IAM=1 (127.0.0.1:4566). Aucun secret n'est stocké dans ce script.

$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "eu-west-3"
$env:AWS_ENDPOINT_URL = "http://localhost:4566"

# Utilisateurs, étiquettes, clés d'accès et profils CLI
$users = @{ alice = "data"; bob = "audit"; claire = "reseau" }
foreach ($u in $users.Keys) {
  aws iam create-user --user-name $u --tags "Key=team,Value=$($users[$u])" | Out-Null
  $k = aws iam create-access-key --user-name $u --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text
  $a, $s = $k -split "\s+"
  aws configure set aws_access_key_id $a --profile $u
  aws configure set aws_secret_access_key $s --profile $u
  aws configure set region eu-west-3 --profile $u
}

# Groupes et appartenances
$groups = @{ developpeurs = "alice"; auditeurs = "bob"; "admins-reseau" = "claire" }
foreach ($g in $groups.Keys) {
  aws iam create-group --group-name $g | Out-Null
  aws iam add-user-to-group --user-name $($groups[$g]) --group-name $g
}

# Lecture seule S3 pour le groupe des auditeurs
aws iam attach-group-policy --group-name auditeurs --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Politique de mot de passe : longueur, historique, changement par l'utilisateur
aws iam update-account-password-policy --minimum-password-length 14 --password-reuse-prevention 5 --allow-users-to-change-password

# Bucket de test
aws s3 mb s3://iam-lab-sensor-1

# Contrôle
aws iam list-users --query "Users[].{Nom:UserName,Equipe:Tags[0].Value}" --output table
aws sts get-caller-identity --profile alice
