import Papa from 'papaparse';
import Web3 from 'web3';

class CarbonEmissionsDataProcessor {
    constructor(web3Provider, dataIngestionAddress, emissionsContractAddress) {
        this.web3 = new Web3(web3Provider);
        this.dataIngestionContract = new this.web3.eth.Contract(
            DataIngestionABI,
            dataIngestionAddress
        );
        this.emissionsContract = new this.web3.eth.Contract(
            EmissionsContractABI,
            emissionsContractAddress
        );
    }

    async processCSVData(csvContent) {
        return new Promise((resolve, reject) => {
            Papa.parse(csvContent, {
                header: true,
                dynamicTyping: true,
                skipEmptyLines: true,
                complete: async (results) => {
                    try {
                        const { data } = results;
                        
                        // Prepare arrays for batch processing
                        const cities = [];
                        const dates = [];
                        const sectors = [];
                        const values = [];
                        
                        data.forEach(row => {
                            cities.push(row.city);
                            dates.push(row.date);
                            sectors.push(row.sector);
                            values.push(this.web3.utils.toWei(row.value.toString()));
                        });
                        
                        // Send data to blockchain in batches
                        const batchSize = 50;
                        for (let i = 0; i < cities.length; i += batchSize) {
                            const cityBatch = cities.slice(i, i + batchSize);
                            const dateBatch = dates.slice(i, i + batchSize);
                            const sectorBatch = sectors.slice(i, i + batchSize);
                            const valueBatch = values.slice(i, i + batchSize);
                            
                            await this.dataIngestionContract.methods
                                .addDataPoints(cityBatch, dateBatch, sectorBatch, valueBatch)
                                .send({ from: this.web3.eth.defaultAccount });
                        }
                        
                        resolve({
                            processedRecords: cities.length,
                            uniqueCities: [...new Set(cities)],
                            uniqueSectors: [...new Set(sectors)]
                        });
                    } catch (error) {
                        reject(error);
                    }
                },
                error: (error) => reject(error)
            });
        });
    }

    async calculateCityMetrics(city) {
        try {
            const stats = await this.dataIngestionContract.methods
                .getCityStats(city)
                .call();
            
            const emissions = await this.emissionsContract.methods
                .getCityMetrics(city)
                .call();
            
            return {
                dataPoints: stats.dataCount,
                totalEmissions: this.web3.utils.fromWei(emissions.totalEmissions),
                averageTemperature: emissions.avgTemp / 100, // Convert from basis points
                averageAQI: emissions.avgAQI,
                creditsRequested: emissions.creditsRequested,
                renewalCount: emissions.renewals
            };
        } catch (error) {
            throw new Error(`Failed to calculate metrics for ${city}: ${error.message}`);
        }
    }

    async processHistoricalData(startDate, endDate) {
        try {
            const events = await this.emissionsContract.getPastEvents('EmissionDataAdded', {
                fromBlock: 0,
                toBlock: 'latest',
                filter: {
                    timestamp: {
                        $gte: startDate.getTime() / 1000,
                        $lte: endDate.getTime() / 1000
                    }
                }
            });

            return events.map(event => ({
                city: event.returnValues.city,
                timestamp: new Date(event.returnValues.timestamp * 1000),
                sector: event.returnValues.sector,
                value: this.web3.utils.fromWei(event.returnValues.value)
            }));
        } catch (error) {
            throw new Error(`Failed to process historical data: ${error.message}`);
        }
    }
}

// Usage example:
async function main() {
    const processor = new CarbonEmissionsDataProcessor(
        'WEB3_PROVIDER_URL',
        'DATA_INGESTION_CONTRACT_ADDRESS',
        'EMISSIONS_CONTRACT_ADDRESS'
    );

    try {
        // Process CSV data
        const csvContent = await fetch('carbon_emissions.csv').then(res => res.text());
        const result = await processor.processCSVData(csvContent);
        console.log(`Processed ${result.processedRecords} records`);

        // Calculate metrics for Melbourne
        const melbourneMetrics = await processor.calculateCityMetrics('Melbourne');
        console.log('Melbourne Metrics:', melbourneMetrics);

        // Process historical data
        const historicalData = await processor.processHistoricalData(
            new Date('2019-01-01'),
            new Date('2019-12-31')
        );
        console.log('Historical Data Points:', historicalData.length);
    } catch (error) {
        console.error('Error processing data:', error);
    }
}
