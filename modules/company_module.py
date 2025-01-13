class CompanyModule:
    def __init__(self, workflow):
        self.workflow = workflow

    async def register_company_data(self, company_data):
        try:
            contract = self.workflow.contracts['CompanyRegister']
            for record in company_data:
                tx_hash = await contract.functions.registerCompany(
                    record['company_name'],
                    record['registration_date'],
                    record['sector'],
                    record['emissions_baseline']
                ).transact()
                receipt = await self.workflow.w3.eth.wait_for_transaction_receipt(tx_hash)
                self.workflow.log_to_file('company_register_logs.json', record, receipt)
        except Exception as e:
            logging.error(f"Error registering company data: {str(e)}")
            raise
