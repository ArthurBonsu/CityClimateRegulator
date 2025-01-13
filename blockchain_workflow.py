import pandas as pd
from web3 import Web3
import json
import logging
from datetime import datetime
import asyncio

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class BlockchainWorkflow:
    def __init__(self, provider_url, contract_addresses):
        self.w3 = Web3(Web3.HTTPProvider(provider_url))
        if not self.w3.isConnected():
            raise ConnectionError("Web3 connection failed.")
        self.contract_addresses = contract_addresses
        self.contracts = {}

    def load_contract(self, name, abi_path):
        try:
            with open(abi_path, 'r') as abi_file:
                abi = json.load(abi_file)
            address = self.contract_addresses[name]
            self.contracts[name] = self.w3.eth.contract(address=Web3.toChecksumAddress(address), abi=abi)
            logging.info(f"Contract {name} loaded successfully.")
        except Exception as e:
            logging.error(f"Error loading contract {name}: {str(e)}")
            raise

    async def run_complete_workflow(self, city_data_path, company_data_path):
        try:
            from modules.city_module import CityModule
            from modules.company_module import CompanyModule
            from modules.emissions_module import EmissionsModule
            from modules.renewal_module import RenewalModule
            from modules.health_module import HealthModule

            city_data = pd.read_csv(city_data_path).to_dict('records')
            company_data = pd.read_csv(company_data_path).to_dict('records')

            city_module = CityModule(self)
            company_module = CompanyModule(self)
            emissions_module = EmissionsModule(self)
            renewal_module = RenewalModule(self)
            health_module = HealthModule(self)

            await city_module.register_city_data(city_data)
            await company_module.register_company_data(company_data)
            await emissions_module.process_emissions_data(city_data)
            await renewal_module.calculate_renewal_metrics(city_data, company_data)
            await health_module.calculate_city_health(city_data)

            summary = self.generate_summary_report()
            logging.info(f"Workflow completed successfully. Summary: {summary}")
        except Exception as e:
            logging.error(f"Error in workflow: {str(e)}")
            raise

    def log_to_file(self, filename, data, receipt):
        try:
            log_entry = {
                "data": data,
                "transactionHash": receipt.transactionHash.hex(),
                "gasUsed": receipt.gasUsed,
                "timestamp": datetime.now().isoformat()
            }
            with open(filename, 'a') as f:
                f.write(json.dumps(log_entry) + '\n')
            logging.info(f"Logged transaction to {filename}")
        except Exception as e:
            logging.error(f"Error logging transaction: {str(e)}")

    def generate_summary_report(self):
        try:
            report = {
                'timestamp': datetime.now().isoformat(),
                'cities_processed': set(),
                'companies_processed': set(),
                'total_transactions': 0,
                'gas_used': 0
            }

            log_files = [
                'city_register_logs.json',
                'company_register_logs.json',
                'emissions_processing_logs.json',
                'renewal_metrics_logs.json',
                'city_health_logs.json'
            ]

            for log_file in log_files:
                try:
                    with open(log_file, 'r') as f:
                        for line in f:
                            data = json.loads(line)
                            if 'city' in data['data']:
                                report['cities_processed'].add(data['data']['city'])
                            if 'company_name' in data['data']:
                                report['companies_processed'].add(data['data']['company_name'])
                            report['total_transactions'] += 1
                            report['gas_used'] += data['gasUsed']
                except FileNotFoundError:
                    continue

            report['cities_processed'] = list(report['cities_processed'])
            report['companies_processed'] = list(report['companies_processed'])

            with open('workflow_summary_report.json', 'w') as f:
                json.dump(report, f, indent=2)

            logging.info("Summary report generated successfully")
            return report
        except Exception as e:
            logging.error(f"Error generating summary report: {str(e)}")
            raise
