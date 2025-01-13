class HealthModule:
    def __init__(self, workflow):
        self.workflow = workflow

    async def calculate_city_health(self, city_data):
        try:
            contract = self.workflow.contracts['CityHealthCalculator']
            df = pd.DataFrame(city_data)
            for city in df['city'].unique():
                city_records = df[df['city'] == city]
                total_emissions = city_records['value'].sum()
                variance = city_records['value'].var()
                peak = city_records['value'].max()
                tx_hash = await contract.functions.calculateCityHealth(
                    city, float(total_emissions), float(variance), float(peak)
                ).transact()
                receipt = await self.workflow.w3.eth.wait_for_transaction_receipt(tx_hash)
                self.workflow.log_to_file('city_health_logs.json', {'city': city}, receipt)
        except Exception as e:
            logging.error(f"Error calculating city health: {str(e)}")
            raise
