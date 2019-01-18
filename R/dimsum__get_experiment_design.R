
#' dimsum__get_experiment_design
#'
#' Get, format and validate metadata from experiment design file.
#'
#' @param dimsum_meta an experiment metadata object (required)
#'
#' @return a data.frame with the validated experiment design 
#' @export
dimsum__get_experiment_design <- function(
  dimsum_meta
  ){
  #Load experimental design
  if(!file.exists(dimsum_meta[["experimentDesignPath"]])){
    stop(paste0("Invalid '", "experimentDesignPath", "' argument (file not found)"), call. = FALSE)
  }
  exp_design <- read.table(dimsum_meta[["experimentDesignPath"]], header = T, stringsAsFactors = F, sep="\t")

  #Add original FASTQ directory
  exp_design[,"pair_directory"] <- dimsum_meta[["fastqFileDir"]]

  #Add sample-specific cutadapt options
  if((!"cutadapt5First" %in% colnames(exp_design) & is.null(dimsum_meta[["cutadapt5First"]])) | (!"cutadapt5Second" %in% colnames(exp_design) & is.null(dimsum_meta[["cutadapt5Second"]]))){
    stop("Sequence of 5' constant region not found. Please check that the 'cutadapt5First' and 'cutadapt5Second' arguments are correctly set.", call. = FALSE)
  }
  if(!"cutadaptCut5First" %in% colnames(exp_design)){exp_design[,"cutadaptCut5First"] <- ifelse(is.null(dimsum_meta[["cutadaptCut5First"]]), NA, dimsum_meta[["cutadaptCut5First"]])}
  if(!"cutadaptCut5Second" %in% colnames(exp_design)){exp_design[,"cutadaptCut5Second"] <- ifelse(is.null(dimsum_meta[["cutadaptCut5Second"]]), NA, dimsum_meta[["cutadaptCut5Second"]])}
  if(!"cutadaptCut3First" %in% colnames(exp_design)){exp_design[,"cutadaptCut3First"] <- ifelse(is.null(dimsum_meta[["cutadaptCut3First"]]), NA, dimsum_meta[["cutadaptCut3First"]])}
  if(!"cutadaptCut3Second" %in% colnames(exp_design)){exp_design[,"cutadaptCut3Second"] <- ifelse(is.null(dimsum_meta[["cutadaptCut3Second"]]), NA, dimsum_meta[["cutadaptCut3Second"]])}
  if(!"cutadapt5First" %in% colnames(exp_design)){exp_design[,"cutadapt5First"] <- ifelse(is.null(dimsum_meta[["cutadapt5First"]]), NA, dimsum_meta[["cutadapt5First"]])}
  if(!"cutadapt5Second" %in% colnames(exp_design)){exp_design[,"cutadapt5Second"] <- ifelse(is.null(dimsum_meta[["cutadapt5Second"]]), NA, dimsum_meta[["cutadapt5Second"]])}
  if(!"cutadapt3First" %in% colnames(exp_design)){exp_design[,"cutadapt3First"] <- ifelse(is.null(dimsum_meta[["cutadapt3First"]]), NA, dimsum_meta[["cutadapt3First"]])}
  if(!"cutadapt3Second" %in% colnames(exp_design)){exp_design[,"cutadapt3Second"] <- ifelse(is.null(dimsum_meta[["cutadapt3Second"]]), NA, dimsum_meta[["cutadapt3Second"]])}
  if(!"cutadaptMinLength" %in% colnames(exp_design)){exp_design[,"cutadaptMinLength"] <- ifelse(is.null(dimsum_meta[["cutadaptMinLength"]]), NA, dimsum_meta[["cutadaptMinLength"]])}
  if(!"cutadaptErrorRate" %in% colnames(exp_design)){exp_design[,"cutadaptErrorRate"] <- ifelse(is.null(dimsum_meta[["cutadaptErrorRate"]]), NA, dimsum_meta[["cutadaptErrorRate"]])}
  #Convert empty string constant region sequences to NA
  exp_design[which(exp_design[,"cutadapt5First"]==""),"cutadapt5First"] <- NA
  exp_design[which(exp_design[,"cutadapt5Second"]==""),"cutadapt5Second"] <- NA
  exp_design[which(exp_design[,"cutadapt3First"]==""),"cutadapt3First"] <- NA
  exp_design[which(exp_design[,"cutadapt3Second"]==""),"cutadapt3Second"] <- NA

  #Check whether experiment design is valid
  dimsum__check_experiment_design(exp_design)

  #Check FASTQ files exist (if demultiplexed FASTQ files supplied i.e. no barcodeDesignPath supplied)
  if(is.null(dimsum_meta[["barcodeDesignPath"]])){
    #Pair1 files
    for(i in unlist(exp_design[,c("pair1")])){
      if(!file.exists(file.path(dimsum_meta[["fastqFileDir"]], i))){
        stop(paste0("Invalid FASTQ file name '", i, "' in experimentDesign file (file not found)"), call. = FALSE)
      }
    }
    #Pair2 files
    for(i in unlist(exp_design[,c("pair2")])){
      if(!file.exists(file.path(dimsum_meta[["fastqFileDir"]], i))){
        stop(paste0("Invalid FASTQ file name '", i, "' in experimentDesign file (file not found)"), call. = FALSE)
      }
    }
  }

  #Check that all FASTQ file prefices exist in barcodeDesign file (if barcodeDesignPath supplied)
  if(!is.null(dimsum_meta[["barcodeDesignPath"]])){
    all_prefices <- unique(gsub("1.fastq|2.fastq", "", unlist(exp_design[,c("pair1", "pair2")])))
    if(sum(!all_prefices %in% dimsum_meta[["barcode_design"]][,"new_pair_prefix"])!=0){
      stop(paste0("One or more FASTQ file names in experimentDesign file didn't match a 'new_pair_prefix' value in barcodeDesign file"), call. = FALSE)
    }
  }

  #If not trans library: reverse complement cutadapt 5' constant regions to obtain 3' constant regions (if not already supplied)
  if(!dimsum_meta[["transLibrary"]]){
    exp_design[is.na(exp_design[,"cutadapt3First"]),"cutadapt3First"] <- as.character(Biostrings::reverseComplement(Biostrings::DNAStringSet(exp_design[is.na(exp_design[,"cutadapt3First"]),"cutadapt5Second"])))
    exp_design[is.na(exp_design[,"cutadapt3Second"]),"cutadapt3Second"] <- as.character(Biostrings::reverseComplement(Biostrings::DNAStringSet(exp_design[is.na(exp_design[,"cutadapt3Second"]),"cutadapt5First"])))
  }

  return(exp_design)
}

