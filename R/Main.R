# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of RehospitalizationPredictionWithNote
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the Study
#'
#' @details
#' This function executes the RehospitalizationPredictionWithNote Study.
#' 
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cdmDatabaseName      Shareable name of the database 
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the target population cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param createProtocol       Creates a protocol based on the analyses specification                             
#' @param createCohorts        Create the cohortTable table with the target population and outcome cohorts?
#' @param runAnalyses          Run the model development
#' @param createResultsDoc     Create a document containing the results of each prediction
#' @param createValidationPackage  Create a package for sharing the models 
#' @param packageResults       Should results be packaged for later sharing?     
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included 
#'                             in packaged results.
#' @param verbosity            Sets the level of the verbosity. If the log level is at or higher in priority than the logger threshold, a message will print. The levels are:
#'                                         \itemize{
#'                                         \item{DEBUG}{Highest verbosity showing all debug statements}
#'                                         \item{TRACE}{Showing information about start and end of steps}
#'                                         \item{INFO}{Show informative information (Default)}
#'                                         \item{WARN}{Show warning messages}
#'                                         \item{ERROR}{Show error messages}
#'                                         \item{FATAL}{Be silent except for fatal errors}
#'                                         }                              
#' @param cdmVersion           The version of the common data model                             
#'
#' @examples
#' \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cdmDatabaseName = 'shareable name of the database'
#'         cohortDatabaseSchema = "study_results",
#'         cohortTable = "cohort",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results", 
#'         createProtocol = T,
#'         createCohorts = T,
#'         runAnalyses = T,
#'         createResultsDoc = T,
#'         createValidationPackage = T,
#'         packageResults = F,
#'         minCellCount = 5,
#'         verbosity = "INFO",
#'         cdmVersion = 5)
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cdmDatabaseName = 'friendly database name',
                    cohortDatabaseSchema = cdmDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = cohortDatabaseSchema,
                    outputFolder,
                    createProtocol = F,
                    createCohorts = F,
                    runAnalyses = F,
                    createResultsDoc = F,
                    createValidationPackage = F,
                    packageResults = F,
                    minCellCount= 5,
                    verbosity = "INFO",
                    cdmVersion = 5,
                    sampleSize = NULL) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  
  OhdsiRTools::addDefaultFileLogger(file.path(outputFolder, "log.txt"))
  
  if(createProtocol){
    createPlpProtocol(outputFolder)
  }
  
  if (createCohorts) {
    OhdsiRTools::logInfo("Creating cohorts")
    createCohorts(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = outputFolder)
  }
  
  if(runAnalyses){
    
    defaultCovariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                           useDemographicsAgeGroup = TRUE,
                                                                           useDemographicsRace = TRUE,
                                                                           useConditionOccurrenceAnyTimePrior = T,
                                                                           useConditionEraAnyTimePrior = FALSE,
                                                                           useConditionGroupEraAnyTimePrior = FALSE, #FALSE,
                                                                           useDrugExposureAnyTimePrior = FALSE,
                                                                           useDrugEraAnyTimePrior = FALSE,
                                                                           useDrugGroupEraAnyTimePrior = FALSE, #FALSE,
                                                                           useProcedureOccurrenceAnyTimePrior = FALSE,
                                                                           useDeviceExposureAnyTimePrior = FALSE,
                                                                           useMeasurementAnyTimePrior =FALSE,
                                                                           useObservationAnyTimePrior = FALSE,
                                                                           useCharlsonIndex = FALSE,
                                                                           useDcsi = FALSE,
                                                                           useChads2 = FALSE,
                                                                           longTermStartDays = -365,
                                                                           mediumTermStartDays = -180, 
                                                                           shortTermStartDays = -30, 
                                                                           endDays = 0)
    ###without note
    plpData<-PatientLevelPrediction::getPlpData(connectionDetails, 
                                                cdmDatabaseSchema,
                                                oracleTempSchema = oracleTempSchema, 
                                                cohortId = c(747), 
                                                outcomeIds = c(748),
                                                studyStartDate = "20050101", 
                                                studyEndDate = "",
                                                cohortDatabaseSchema = cohortDatabaseSchema, 
                                                cohortTable = cohortTable,
                                                outcomeDatabaseSchema = cohortDatabaseSchema, 
                                                outcomeTable = cohortTable,
                                                cdmVersion = "5", 
                                                firstExposureOnly = FALSE, 
                                                washoutPeriod = 0,
                                                sampleSize = sampleSize, 
                                                covariateSettings=defaultCovariateSettings, 
                                                excludeDrugsFromCovariates = FALSE,
                                                baseUrl = NULL)
    
    studyPopulation<-PatientLevelPrediction::createStudyPopulation(plpData, 
                                                                   population = NULL, 
                                                                   outcomeId = c(748), 
                                                                   binary = T,
                                                                   includeAllOutcomes = T, 
                                                                   firstExposureOnly = FALSE, 
                                                                   washoutPeriod = 0,
                                                                   removeSubjectsWithPriorOutcome = FALSE, 
                                                                   priorOutcomeLookback = 99999,
                                                                   requireTimeAtRisk = T, 
                                                                   minTimeAtRisk = 29, riskWindowStart = 1,
                                                                   addExposureDaysToStart = FALSE, 
                                                                   riskWindowEnd = 30,
                                                                   addExposureDaysToEnd = F)
    
    lassoLogisticSetting<-PatientLevelPrediction::setLassoLogisticRegression()
    
    result<-      PatientLevelPrediction::runPlp(population=studyPopulation,
                                                 plpData=plpData,
                                                 minCovariateFraction = 0.0001, 
                                                 normalizeData = T,
                                                 modelSettings =lassoLogisticSetting, 
                                                 testSplit = "person", 
                                                 testFraction = 0.25,
                                                 trainFraction = NULL, 
                                                 splitSeed = NULL, 
                                                 nfold = 3, 
                                                 indexes = NULL,
                                                 saveDirectory = file.path(outputFolder,"Analysis_lasso") ,
                                                 savePlpData = T, 
                                                 savePlpResult = T,
                                                 savePlpPlots = T, 
                                                 saveEvaluation = F, verbosity = "INFO",
                                                 timeStamp = FALSE, 
                                                 analysisId = NULL
    )
    PatientLevelPrediction::savePlpModel(result$model,dirPath = file.path(outputFolder,"Analysis_lasso"))
    PatientLevelPrediction::savePlpResult(result,file.path(outputFolder,"Analysis_lasso"))
    
    gbmSetting<-PatientLevelPrediction::setGradientBoostingMachine()
    result<-      PatientLevelPrediction::runPlp(population=studyPopulation,
                                                 plpData=plpData,
                                                 minCovariateFraction = 0.0001, 
                                                 normalizeData = T,
                                                 modelSettings =gbmSetting, 
                                                 testSplit = "person", 
                                                 testFraction = 0.25,
                                                 trainFraction = NULL, 
                                                 splitSeed = NULL, 
                                                 nfold = 3, 
                                                 indexes = NULL,
                                                 saveDirectory = file.path(outputFolder,"Analysis_gbm") ,
                                                 savePlpData = T, 
                                                 savePlpResult = T,
                                                 savePlpPlots = T, 
                                                 saveEvaluation = F, verbosity = "INFO",
                                                 timeStamp = FALSE, 
                                                 analysisId = NULL
    )
    PatientLevelPrediction::savePlpModel(result$model,dirPath = file.path(outputFolder,"Analysis_gbm"))
    PatientLevelPrediction::savePlpResult(result,file.path(outputFolder,"Analysis_gbm"))
    
    ###with note
    defaultTopicModel <- noteCovariateExtraction::loadDefaultTopicModel(c(44814637),c('KOR'),'base')
    
    noteCovSet<-noteCovariateExtraction::createTopicFromNoteSettings(noteConceptId = c(44814637),
                                                                     existingTopicModel = defaultTopicModel,
                                                                     buildTopicModeling= FALSE,
                                                                     useDictionary=FALSE,
                                                                     limitedMedicalTermOnlyLanguage = c('KOR','ENG'),
                                                                     nGram = defaultTopicModel$nGramSetting,
                                                                     buildTopidModelMinFrac = 0.001,
                                                                     buildTopidModelMaxFrac = 0.5,
                                                                     useTextToVec = FALSE,
                                                                     useTopicModeling=FALSE,
                                                                     optimalTopicValue =FALSE,
                                                                     numberOfTopics=defaultTopicModel$numberOfTopics,
                                                                     sampleSize=-1)
    
    covariateSettingList <- list(defaultCovariateSettings,
      noteCovSet
    ) 
    
    plpData<-PatientLevelPrediction::getPlpData(connectionDetails, 
                                                cdmDatabaseSchema,
                                                oracleTempSchema = oracleTempSchema, 
                                                cohortId = c(747), 
                                                outcomeIds = c(748),
                                                studyStartDate = "20050101", 
                                                studyEndDate = "",
                                                cohortDatabaseSchema = cohortDatabaseSchema, 
                                                cohortTable = cohortTable,
                                                outcomeDatabaseSchema = cohortDatabaseSchema, 
                                                outcomeTable = cohortTable,
                                                cdmVersion = "5", 
                                                firstExposureOnly = FALSE, 
                                                washoutPeriod = 0,
                                                sampleSize = sampleSize, 
                                                covariateSettings=covariateSettingList, 
                                                excludeDrugsFromCovariates = FALSE,
                                                baseUrl = NULL)
    
    studyPopulation<-PatientLevelPrediction::createStudyPopulation(plpData, 
                                                                   population = NULL, 
                                                                   outcomeId = c(748), 
                                                                   binary = T,
                                                                   includeAllOutcomes = T, 
                                                                   firstExposureOnly = FALSE, 
                                                                   washoutPeriod = 0,
                                                                   removeSubjectsWithPriorOutcome = FALSE, 
                                                                   priorOutcomeLookback = 99999,
                                                                   requireTimeAtRisk = T, 
                                                                   minTimeAtRisk = 29, riskWindowStart = 1,
                                                                   addExposureDaysToStart = FALSE, 
                                                                   riskWindowEnd = 30,
                                                                   addExposureDaysToEnd = F)
    
    lassoLogisticSetting<-PatientLevelPrediction::setLassoLogisticRegression()
    
    result<-      PatientLevelPrediction::runPlp(population=studyPopulation,
                                                 plpData=plpData,
                                                 minCovariateFraction = 0.0001, 
                                                 normalizeData = T,
                                                 modelSettings =lassoLogisticSetting, 
                                                 testSplit = "person", 
                                                 testFraction = 0.25,
                                                 trainFraction = NULL, 
                                                 splitSeed = NULL, 
                                                 nfold = 3, 
                                                 indexes = NULL,
                                                 saveDirectory = file.path(outputFolder,"Analysis_lasso_note") ,
                                                 savePlpData = T, 
                                                 savePlpResult = T,
                                                 savePlpPlots = T, 
                                                 saveEvaluation = F, verbosity = "INFO",
                                                 timeStamp = FALSE, 
                                                 analysisId = NULL
    )
    PatientLevelPrediction::savePlpModel(result$model,dirPath = file.path(outputFolder,"Analysis_lasso_note"))
    PatientLevelPrediction::savePlpResult(result,file.path(outputFolder,"Analysis_lasso_note"))
    
    gbmSetting<-PatientLevelPrediction::setGradientBoostingMachine()
    result<-      PatientLevelPrediction::runPlp(population=studyPopulation,
                                                 plpData=plpData,
                                                 minCovariateFraction = 0.0001, 
                                                 normalizeData = T,
                                                 modelSettings =gbmSetting, 
                                                 testSplit = "person", 
                                                 testFraction = 0.25,
                                                 trainFraction = NULL, 
                                                 splitSeed = NULL, 
                                                 nfold = 3, 
                                                 indexes = NULL,
                                                 saveDirectory = file.path(outputFolder,"Analysis_gbm_note") ,
                                                 savePlpData = T, 
                                                 savePlpResult = T,
                                                 savePlpPlots = T, 
                                                 saveEvaluation = F, verbosity = "INFO",
                                                 timeStamp = FALSE, 
                                                 analysisId = NULL
    )
    PatientLevelPrediction::savePlpModel(result$model,dirPath = file.path(outputFolder,"Analysis_gbm_note"))
    PatientLevelPrediction::savePlpResult(result,file.path(outputFolder,"Analysis_gbm_note"))
    
    # OhdsiRTools::logInfo("Running predictions")
    # 
    # predictionAnalysisListFile <- system.file("settings",
    #                                           "predictionAnalysisList.json",
    #                                           package = "RehospitalizationPredictionWithNote")
    # predictionAnalysisList <- PatientLevelPrediction::loadPredictionAnalysisList(predictionAnalysisListFile)
    # predictionAnalysisList$connectionDetails = connectionDetails
    # predictionAnalysisList$cdmDatabaseSchema = cdmDatabaseSchema
    # predictionAnalysisList$cdmDatabaseName = cdmDatabaseName
    # predictionAnalysisList$oracleTempSchema = oracleTempSchema
    # predictionAnalysisList$cohortDatabaseSchema = cohortDatabaseSchema
    # predictionAnalysisList$cohortTable = cohortTable
    # predictionAnalysisList$outcomeDatabaseSchema = cohortDatabaseSchema
    # predictionAnalysisList$outcomeTable = cohortTable
    # predictionAnalysisList$cdmVersion = cdmVersion
    # predictionAnalysisList$outputFolder = outputFolder
    # predictionAnalysisList$verbosity = verbosity
    # 
    #result <- do.call(PatientLevelPrediction::runPlpAnalyses, predictionAnalysisList)
    
    
  }
  
  if (packageResults) {
    OhdsiRTools::logInfo("Packaging results")
    packageResults(outputFolder = outputFolder,
                   minCellCount = minCellCount)
  }
  
  if(createResultsDoc){
    createMultiPlpReport(analysisLocation=outputFolder,
                         protocolLocation = file.path(outputFolder,'protocol.docx'),
                         includeModels = F)
  }
  
  if(createValidationPackage){
    predictionAnalysisListFile <- system.file("settings",
                                              "predictionAnalysisList.json",
                                              package = "RehospitalizationPredictionWithNote")
    jsonSettings <-  tryCatch({Hydra::loadSpecifications(file=predictionAnalysisListFile)},
                              error=function(cond) {
                                stop('Issue with json file...')
                              })
    pn <- jsonlite::fromJSON(jsonSettings)$packageName
    jsonSettings <- gsub(pn,paste0(pn,'Validation'),jsonSettings)
    jsonSettings <- gsub('PatientLevelPredictionStudy','PatientLevelPredictionValidationStudy',jsonSettings)
    
    
    createValidationPackage(modelFolder = outputFolder, 
                            outputFolder = file.path(outputFolder, paste0(pn,'Validation')),
                            minCellCount = minCellCount,
                            databaseName = cdmDatabaseName,
                            jsonSettings = jsonSettings )
  }
  
  
  invisible(NULL)
  
  
  
}
