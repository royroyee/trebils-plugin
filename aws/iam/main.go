package main

import (
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/iam"
	"os"
)

func main() {
	// Fetch AWS authentication information from environment variables
	awsAccessKeyID := os.Getenv("AWS_ACCESS_KEY_ID")
	awsSecretAccessKey := os.Getenv("AWS_SECRET_ACCESS_KEY")

	// Check if the credentials are set
	if awsAccessKeyID == "" || awsSecretAccessKey == "" {
		fmt.Println("AWS authentication information is missing. Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables.")
		return
	}

	// Initialize AWS session configuration
	config := &aws.Config{
		Region: aws.String("us-east-1"), // Set region
		Credentials: credentials.NewStaticCredentials(
			awsAccessKeyID,
			awsSecretAccessKey,
			"", // Leave the token empty if not needed
		),
	}
	sess, err := session.NewSession(config)
	if err != nil {
		fmt.Println("Failed to create AWS session:", err)
		return
	}

	// Create IAM service client
	svc := iam.New(sess)

	// Fetch list of IAM users
	input := &iam.ListUsersInput{}
	result, err := svc.ListUsers(input)
	if err != nil {
		fmt.Println("Failed to fetch IAM users list:", err)
		return
	}

	// Print list of IAM users
	for i, user := range result.Users {
		fmt.Printf("%d: %s\n", i+1, aws.StringValue(user.UserName))
	}
}
