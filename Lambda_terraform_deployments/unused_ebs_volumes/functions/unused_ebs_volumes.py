import boto3
import json

def list_available_volumes():
    ec2_client = boto3.client('ec2')
    sns_client= boto3.client('sns')

    #list all EBS Volumes
    volumes = ec2_client.describe_volumes()

    # initialize a list to store volume IDs tagged for deletion
    tagged_volumes =[]
    # Tag unused volumes for deletion
    for volume in volumes['Volumes']:
        volume_id = volume['VolumeId']
        state = volume['state']

        if state == 'available':

            # check existing tags for the volume
            existing_tags = ec2_client.describe_tags(Filters=[{'Name': 'resource-id', 'Values': [volume_id]}])['Tags']
            # Check if 'ToDelete' tag is not already present
            if not any(tag['Key'] == 'ToDelete' for tag in existing_tags):
                ec2_client.create_tags(
                    Resources=[volume_id],
                    Tags=[{'Key': 'ToDelete', 'Value': 'Yes'}]
                )
                tagged_volumes.append(volume_id)

                print(f"Volume {volume_id} tagged for deletion.")
            else:
                print(f"Volume {volume_id} is already tagged for deletion.")

        else:
            print(f"Volume {volume_id} is in use and will not be tagged for deletion")

    # publish the list of volumes tagged for deletion to an sns topic
    sns_topic_arn = ""

    if tagged_volumes:
        message = f'Hello,\n\n' \
        f'The following Unused EBS volumes has been tagged for deletion: {tagged_volumes}'\
        'please verify and remove the delete tag if the volume is still required'\
        'if the delete tag is still present within the next 5days, the volume will be deleted.\n'

        sns_client.publish(TopicArn=sns_topic_arn, Message=message,
                           Subject=f'List of available EBS volumes to be cleaned-up')
        print(f'List of available EBS volumes published to SNS topic {sns_topic_arn}')

    return {
        'statusCode': 200,
        'body': f'Unused volumes published to SNS topic {sns_topic_arn}'
    }

def delete_unused_volumes():
    ec2_client = boto3.client('ec2')
    sns_client= boto3.client('sns')

    #list all EBS Volumes with the 'ToDelete tag
    tagged_volumes = ec2_client.describe_volumes(Filters=[{'Name': 'tag:ToDelete', 'Value': ['Yes']}])('Volumes')

    # initialize a list to store volumes deleted
    deleted_volumes =[]
    # Delete Volumes with the 'ToDelete' tag
    for volume in tagged_volumes:
        volume_id = volume['VolumeId']
        
        # Delete the volume
        ec2_client.delete_volume(VolumeId=volume_id)

        deleted_volumes.append(volume_id)
        print(f'Volume {volume_id} deleted')

        
    # publish the list of deleted to an sns topic
    sns_topic_arn = ""

    if deleted_volumes:
        message = f'Hello,\n\n' \
        f'The following Unused EBS volumes that were marked for deletion has been deleted.'\
        f'{deleted_volumes}\n'

        sns_client.publish(TopicArn=sns_topic_arn, Message=message,
                           Subject=f'List of available EBS volumes to be cleaned-up')
        print(f'List of deleted EBS volumes published to SNS topic {sns_topic_arn}')

    return {
        'statusCode': 200,
        'body': f'Deleted volumes: {deleted_volumes}'
    }

def lambda_handler(event, context):
    action=event["action"]
    print(f'Detected action: {action}')

    if action == "list":
        list_available_volumes()
    elif action == "delete":
        delete_unused_volumes()