# pylint: disable=redefined-outer-name
# pylint: disable=import-error
from pathlib import Path
import pandas as pd
import pandas_redshift as pr
from decouple import config


def ingets_to_redshift():

    # extract
    data_path = Path("output.csv")

    df_chunk = pd.read_csv(data_path, chunksize=200000)
    print("data read in chuncks")

    chunk_lst = list(df_chunk)
    df = pd.concat(chunk_lst)
    print("concat chuncks completed..")

    pr.connect_to_redshift(
        dbname="dev",
        host="dbt-cluster.cg8akmqmv2lj.af-south-1.redshift.amazonaws.com",
        port=5439,
        user=config("redshift_usr"),
        password=config("redshift_password"),
    )
    print("conected to cluster")

    # Connect to S3
    pr.connect_to_s3(
        aws_access_key_id=config("aws_access_key_id"),
        aws_secret_access_key=config("aws_secret_access_key"),
        bucket="dbt-s3",
    )
    print("connected to s3")

    # Write the DataFrame to S3 and then to redshift
    pr.pandas_to_redshift(
        data_frame=df, redshift_table_name="dbt_transform", append=False
    )
    print("write to redshift complete")


if __name__ == "__main__":
    ingets_to_redshift()
