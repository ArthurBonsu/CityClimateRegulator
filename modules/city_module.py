class CityModule:
    def __init__(self, workflow):
        self.workflow = workflow

    async def register_city_data(self, city_data):
        try:
            contract = self.workflow.contracts['CityRegister']
            for record in city_data:
                tx_hash = await contract.functions.registerCity(
                    record['city'],
                    record['date'],
                    record['sector'],
                    float(record['value'])
                ).transact()
                receipt = await self.workflow.w3.eth.wait_for_transaction_receipt(tx_hash)
                self.workflow.log_to_file('city_register_logs.json', record, receipt)
        except Exception as e:
            logging.error(f"Error registering city data: {str(e)}")
            raise
