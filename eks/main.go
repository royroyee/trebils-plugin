package main

import (
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eks"
)

func main() {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String("ap-northeast-2"), // Asia/Seoul
	})

	if err != nil {
		fmt.Println("Error creating session:", err)
		return
	}

	svc := eks.New(sess)

	result, err := svc.ListClusters(&eks.ListClustersInput{})

	if err != nil {
		fmt.Println("Error listing clusters:", err)
		return
	}

	for _, cluster := range result.Clusters {
		clusterInfo, err := svc.DescribeCluster(&eks.DescribeClusterInput{
			Name: cluster,
		})
		if err != nil {
			fmt.Println("Error describing cluster:", err)
			return
		}

		fmt.Printf("Cluster Name: %s, Status: %s\n", aws.StringValue(cluster), aws.StringValue(clusterInfo.Cluster.Status))
	}
}
