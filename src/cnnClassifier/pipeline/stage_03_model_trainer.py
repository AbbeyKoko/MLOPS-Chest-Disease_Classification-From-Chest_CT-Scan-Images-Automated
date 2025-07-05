from cnnClassifier.configuration.configuration import ConfigurationManager
from cnnClassifier.components.model_trainer import Training

from cnnClassifier.logger import LoggerManager


STAGE_NAME = "Training Stage"

class ModelTrainingPipeline:
  def __init__(self):
    pass
    
  def main(self):
    config = ConfigurationManager()
    training_config = config.get_training_config()

    training = Training(config=training_config)
    training.get_base_model()
    training.train_valid_generator()
    training.train()


if __name__ == "__main__":
  logger = LoggerManager("ModelTrainingPipeline").get_logger()
  try:
    logger.info("*************************")
    logger.info(f">>>>>> stage {STAGE_NAME} started <<<<<<")
    obj = ModelTrainingPipeline()
    obj.main()
    logger.info(f">>>>>> stage {STAGE_NAME} completed <<<<<<\n\nx==========x")
  except Exception as e:
    logger.exception(e)
    raise e