import os
import zipfile
import gdown

from cnnClassifier.utils.common import get_size
from cnnClassifier.entity.config_entity import DataIngestionConfig
from cnnClassifier.logger import LoggerManager

class DataIngestion:
    def __init__(self, config: DataIngestionConfig):
        self.logger = LoggerManager(self.__class__.__name__).get_logger()
        self.config = config

    def download_file(self) -> str:
        """
        Fetch the data from the url
        """

        try:
            dataset_url = self.config.source_URL
            zip_download_dir = self.config.local_data_file
            os.makedirs(self.config.root_dir, exist_ok=True)
            self.logger.info(
                f"Downloading data from {dataset_url} into filw {zip_download_dir}"
            )

            file_id = dataset_url.split("/")[-2]
            prefix = "https://drive.google.com/uc?/export=download&id="
            gdown.download(prefix + file_id, zip_download_dir)
            self.logger.info(
                f"Downloaded data from {dataset_url} into filw {zip_download_dir}"
            )

        except Exception as e:
            raise e

    def extract_zip_file(self):
        """
        zip_file_path: str
        Extracts the zip file into the data directory
        Function returns None
        """

        unzip_path = self.config.unzip_dir
        os.makedirs(unzip_path, exist_ok=True)
        with zipfile.ZipFile(self.config.local_data_file, "r") as zip_ref:
            zip_ref.extractall(unzip_path)
