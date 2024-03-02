resource "aws_iam_role" "example" {
  name = "example"

  assume_role_policy = "..."
}

resource "aws_iam_instance_profile" "example" {
  role = aws_iam_role.example.name
}

resource "aws_iam_role_policy" "example" {
  name   = "example"
  role   = aws_iam_role.example.name
  policy = jsonencode({
    "Statement" = [{
      "Action" = "s3:*",
      "Effect" = "Allow",
    }],
  })
}

resource "aws_instance" "example" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.example

  # Однак, якщо програмному забезпеченню, запущеному в цьому екземплярі EC2, потрібен доступ
  # до S3 API для коректного завантаження, існує також "прихована"
  # залежність від політики aws_iam_role_policy, яку Terraform не може
  # автоматично вивести, тому вона має бути оголошена явно:
  depends_on = [
    aws_iam_role_policy.example
  ]
}
