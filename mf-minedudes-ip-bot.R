# Load dependencies ------------------------------------------------------------
if (!require(pacman)) {
  install.packages("pacman")
  library(pacman)
}

pacman::p_load(purrr, magrittr, glue, logger, discordr)

# Set up logger ----------------------------------------------------------------
log_file <- file.path("./log", glue::glue("{Sys.Date()}-mf-minedudes-ip-bot.log"))
logger::log_appender(appender = appender_tee(log_file))

# Set global variables ---------------------------------------------------------
webhook <- Sys.getenv("MF_MINEDUDES_WEBHOOK")
username <- Sys.getenv("MF_MINEDUDES_USER")
port <- Sys.getenv("MF_MINEDUDES_PORT")
ip_file <- "./data/ip.RDS"
send_log <- FALSE

# Define helper functions ------------------------------------------------------
validate_ip <- function(ip) {
  valid <- grepl("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", ip)
  if (!valid) {
    logger::log_fatal("Invalid IP detected: {ip}")
    stop()
  }
}

# Compare current public IP to the previous one --------------------------------
tryCatch(
  {

    # Retrieve current public IP from opendns.com
    current_ip <- system(
      "dig +short myip.opendns.com @resolver1.opendns.com",
      intern = TRUE
    )
    logger::log_info("Current IP: {current_ip}")

    # Handle missing ip_file
    if (!file.exists(ip_file)) {
      logger::log_warn("{ip_file} does not exist. Saving current IP: {current_ip}")
      saveRDS(current_ip, ip_file)
      previous_ip <- current_ip
    } else {
      previous_ip <- readRDS(ip_file)
      logger::log_info("Previous IP: {previous_ip}")
    }

    # Validate IP addresses
    purrr::walk(c(previous_ip, current_ip), validate_ip)

    # Send message to discord channel if the public IP has changed
    if (current_ip != previous_ip) {
      logger::log_warn("Current IP does not match the previous IP!")
      # Connect to discord channel
      logger::log_info("Connecting to discord channel.")
      con <- discordr::create_discord_connection(
        webhook = webhook, username = username, set_default = TRUE
      )
      # Send message
      msg <- glue::glue("The IP address to the MF MINEDUDES server has changed from {previous_ip}:{port} to {current_ip}:{port}")
      logger::log_info("Sending message: {msg}")
      discordr::send_webhook_message(msg)
      # Checkpoint the new IP
      saveRDS(current_ip, ip_file)
    } else {
      logger::log_info("No changes were detected between the current and previous IP.")
    }

    logger::log_success("The MF MINEDUDES IP bot script completed successfully!")
  },
  error = function(e) {
    send_log <<- TRUE
    logger::log_error("Error(s) occured with the MF MINEDUDES IP bot script!")
    logger::log_trace("{e}")
  },
  warning = function(w) {
    logger::log_warn("Warning(s) occurred with the MF MINEDUDES IP bot script!")
  },
  finally = {
    if (send_log) {
      con <- discordr::create_discord_connection(
        webhook = webhook, username = username, set_default = TRUE
      )
      discordr::send_webhook_file(filename = log_file, conn = con)
    }
  }
)
