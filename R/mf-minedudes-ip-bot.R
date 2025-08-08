# Set global variables ---------------------------------------------------------
webhook <- Sys.getenv("MF_MINEDUDES_WEBHOOK")
username <- Sys.getenv("MF_MINEDUDES_USER")
channel <- Sys.getenv("MF_MINEDUDES_CHANNEL")
port <- Sys.getenv("MF_MINEDUDES_PORT")
ip_file <- "./data/ip.RDS"
today <- lubridate::today()
n_days <- 7
log_suffix <- "mf-minedudes-ip-bot.log"
log_dir <- "./log"
log_file <- file.path("./log", glue::glue("{today}-{log_suffix}"))

# Define helper functions ------------------------------------------------------
validate_ip <- function(ip) {
  valid <- grepl("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", ip)
  if (!valid) {
    logger::log_fatal("Invalid IP detected: {ip}")
    stop()
  }
}

# Define helper to remove old log files
remove_old_logs <- function(today, n_days = 7, log_dir, log_suffix) {

  # Determine date from n_days ago
  start_date <- today - lubridate::days(n_days)

  # Determine today's date
  end_date <- today

  # Create sequence of dates between start and end date
  days <- seq(start_date, end_date, by = "days")

  # Create list of all log files
  logs <- list.files(
    path = log_dir,
    pattern = paste0("^\\d{4}\\-\\d{2}\\-\\d{2}\\-", log_suffix),
    full.names = TRUE
  )

  # Identify logs that are older than n_days
  old_logs <- logs[!
  grepl(
    pattern = paste("^", days, collapse = "|", sep = ""),
    x = basename(logs)
  )]

  # Remove log files that are older than n_days
  file.remove(old_logs)
}

# Set up logger ----------------------------------------------------------------

# Call the remove old log file helper
remove_old_logs(
  today = today, n_days = n_days, log_dir = log_dir, log_suffix = log_suffix
  )

# Create/append today's log file
logger::log_appender(appender = logger::appender_tee(log_file))

# Main -------------------------------------------------------------------------
tryCatch(
  {
    logger::log_info("Starting the MF MINEDUDES IP bot script.")

    # Retrieve current public IP from opendns.com
    current_ip <- system(
      "curl -4 ifconfig.me",
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
        webhook, 
        username = username, 
        channel_name = channel,
        set_default = TRUE
      )

      if (is.null(con$webhook) || con$webhook == "") {
        logger::log_error("Error: MF_MINEDUDES_WEBHOOK environment variable is not set or empty.")
        stop()
      }

      # Send message
      msg <- glue::glue("The IP address to the MF MINEDUDES server is {current_ip}:{port}")
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
    logger::log_error("Error(s) occured with the MF MINEDUDES IP bot script!")
    logger::log_trace("{e}")
  },
  warning = function(w) {
    logger::log_warn("Warning(s) occurred with the MF MINEDUDES IP bot script!")
  }
)
