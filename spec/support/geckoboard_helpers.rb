module GeckoboardHelpers
  # Use this to stub out the API calls that will be made to Geckoboard.
  # It will return the webmock POST request, which can be used to write
  # expectations about the request being made.
  def stub_geckoboard_dataset_update(dataset_id = "claims.test")
    stub_geckoboard_dataset_find_or_create(dataset_id)
    stub_geckoboard_dataset_post(dataset_id)
  end

  def stub_geckoboard_dataset_find_or_create(dataset_id)
    dataset_fields = {
      reference: {
        name: "Reference",
        type: "string"
      },
      policy: {
        name: "Policy",
        type: "string"
      },
      submitted_at: {
        name: "Submitted at",
        type: "datetime"
      },
      sla_status: {
        name: "SLA status",
        type: "string"
      },
      check: {
        name: "Check",
        type: "string"
      },
      checked_at: {
        name: "Checked at",
        type: "datetime"
      },
      number_of_days_to_check: {
        name: "Number of days to check",
        optional: true,
        type: "number"
      },
      paid: {
        name: "Paid",
        type: "string"
      },
      paid_at: {
        name: "Paid at",
        type: "datetime"
      },
      award_amount: {
        name: "Award amount",
        optional: true,
        type: "money",
        currency_code: "GBP"
      }
    }

    stub_request(:put, "https://api.geckoboard.com/datasets/#{dataset_id}")
      .with(
        body: {
          fields: dataset_fields,
          unique_by: ["reference"]
        }.to_json
      )
      .to_return(status: 200, body: {
        id: dataset_id,
        fields: dataset_fields,
        unique_by: ["reference"]
      }.to_json)
  end

  def stub_geckoboard_dataset_post(dataset_id)
    stub_request(:post, "https://api.geckoboard.com/datasets/#{dataset_id}/data")
  end

  def stub_geckoboard_dataset_delete(dataset_id)
    stub_request(:delete, "https://api.geckoboard.com/datasets/#{dataset_id}")
  end

  def request_body_matches_geckoboard_data_for_claims?(request, claims)
    expected_claims_data = claims.map { |claim|
      {
        "reference" => claim.reference,
        "policy" => claim.policy.to_s,
        "submitted_at" => claim.submitted_at&.strftime("%Y-%m-%dT%H:%M:%S%:z"),
        "sla_status" => if claim.decision_deadline_date.past?
                          "passed"
                        elsif claim.deadline_warning_date.past?
                          "warning"
                        else
                          "ok"
                        end,
        "check" => claim.latest_decision.present? ? claim.latest_decision.result : "unchecked",
        "checked_at" => (claim.latest_decision.present? ? claim.latest_decision.created_at : DateTime.parse("1970-01-01")).strftime("%Y-%m-%dT%H:%M:%S%:z"),
        "number_of_days_to_check" => claim.latest_decision&.number_of_days_since_claim_submitted,
        "paid" => claim.scheduled_for_payment?.to_s,
        "paid_at" => (claim.scheduled_for_payment? ? claim.scheduled_payment_date : DateTime.parse("1970-01-01")).strftime("%Y-%m-%dT%H:%M:%S%:z"),
        "award_amount" => claim.eligibility.present? ? (claim.award_amount * 100).to_i : nil
      }
    }.sort_by { |d| d["reference"] }

    data = JSON.parse(request.body)["data"].sort_by { |d| d["reference"] }
    expected_claims_data == data
  end
end
