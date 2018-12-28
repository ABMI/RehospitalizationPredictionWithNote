# Copyright 2018 Observational Health Data Sciences and Informatics
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

#' Create the analyses details
#'
#' @details
#' This function creates files specifying the analyses that will be performed.
#'
#' @param workFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#'
#' @export
#' 
#' 
#' 

createAnalysesDetails <- function(workFolder) {
   # 1) ADD MODELS you want
  modelSettingList <- list(#PatientLevelPrediction::setAdaBoost(nEstimators = c(10,50,100), learningRate = c(0.5,0.9,1)),
                           PatientLevelPrediction::setLassoLogisticRegression(),
                           PatientLevelPrediction::setGradientBoostingMachine()#, 
                           #setCIReNN(), 
                           #setCNNTorch(), 
                           #setCovNN(), 
                           #setCovNN2(), 
                           #setDecisionTree(), 
                           #setDeepNN(), 
                           #setKNN(), 
                        #setLRTorch(), 
                        #setMLP(), 
                        #setMLPTorch(), 
                        #setNaiveBayes(), 
                        #setRandomForest(), 
                        #setRNNTorch()
                        )
  
  # 2) ADD POPULATIONS you want
  
  pop1 <- PatientLevelPrediction::createStudyPopulationSettings(riskWindowStart = 1, 
                                                                riskWindowEnd = 30,
                                                                requireTimeAtRisk = T, 
                                                                minTimeAtRisk = 29, 
                                                                includeAllOutcomes = T)
  # pop2 <- createStudyPopulationSettings(riskWindowStart = 1, 
  #                                       riskWindowEnd = 365,
  #                                       requireTimeAtRisk = T, 
  #                                       minTimeAtRisk = 364, 
  #                                       includeAllOutcomes = F)
  populationSettingList <- list(pop1
                                #, pop2
                                )
  
  # 3) ADD COVARIATES settings you want
  defaultCovariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                         useDemographicsAgeGroup = TRUE,
                                                                         useDemographicsRace = TRUE,
                                                                         useConditionOccurrenceAnyTimePrior = T,
                                                                         useConditionEraAnyTimePrior = TRUE,
                                                                         useConditionGroupEraAnyTimePrior = TRUE, #FALSE,
                                                                         useDrugExposureAnyTimePrior = T,
                                                                         useDrugEraAnyTimePrior = TRUE,
                                                                         useDrugGroupEraAnyTimePrior = TRUE, #FALSE,
                                                                         useProcedureOccurrenceAnyTimePrior = T,
                                                                         useDeviceExposureAnyTimePrior = T,
                                                                         useMeasurementAnyTimePrior =T,
                                                                         useObservationAnyTimePrior = T,
                                                                         useCharlsonIndex = TRUE,
                                                                         useDcsi = TRUE,
                                                                         useChads2 = TRUE,
                                                                         longTermStartDays = -365,
                                                                         mediumTermStartDays = -180, 
                                                                         shortTermStartDays = -30, 
                                                                         endDays = 0)
  
  defaultTopicModel <- noteCovariateExtraction::loadDefaultTopicModel(c(44814637),c('KOR'))
  noteCovSet<-noteCovariateExtraction::createTopicFromNoteSettings(useTopicFromNote = TRUE,
                                                                   noteConceptId = c(44814637),
                                                                   useDictionary= FALSE,
                                                                   targetLanguage = c('KOR','ENG'),
                                                                   nGram = 1L,
                                                                   buildTopicModeling= FALSE,
                                                                   buildTopidModelMinFrac = 0.01,
                                                                   existingTopicModel = defaultTopicModel,
                                                                   useCustomTopicModel = FALSE,
                                                                   useTextToVec = FALSE,
                                                                   useTopicModeling=TRUE,
                                                                   numberOfTopics=4000L,
                                                                   optimalTopicValue =FALSE,
                                                                   useGloVe = FALSE,
                                                                   latentDimensionForGlove = 100L,
                                                                   useAutoencoder=FALSE,
                                                                   latentDimensionForAutoEncoder = 100L,
                                                                   sampleSize=-1)

  
  covariateSettingList <- list(defaultCovariateSettings, noteCovSet) 
  
  # ADD COHORTS
  cohortIds <- c(747#,
                 )  # add all your Target cohorts here
  outcomeIds <- c(748
                  #2,3
                  )   # add all your outcome cohorts here
  
  
  # this will then generate and save the json specification for the analysis
    PatientLevelPrediction::savePredictionAnalysisList(workFolder=workFolder,
                                         cohortIds,
                                         outcomeIds,
                                        cohortSettingCsv =file.path(workFolder, 'CohortsToCreate.csv'), 
                              
                                        covariateSettingList=covariateSettingList,
                                        populationSettingList=populationSettingList,
                                        modelSettingList=modelSettingList,
                                         
                                         maxSampleSize= NULL,
                                         washoutPeriod=0,
                                         minCovariateFraction=0.01,
                                         normalizeData=T,
                                         testSplit='person',
                                         testFraction=0.25,
                                         splitSeed=1,
                                         nfold=3
                                         )

  }