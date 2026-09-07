class TaxRateOption {
  final String label;
  final double rate;

  const TaxRateOption(this.label, this.rate);
}

const List<TaxRateOption> kTaxRateOptions = [
  TaxRateOption('None', 0.0),
  TaxRateOption('Exempted', 0.0),
  TaxRateOption('GST@0%', 0.0),
  TaxRateOption('IGST@0%', 0.0),
  TaxRateOption('GST@0.25%', 0.25),
  TaxRateOption('IGST@0.25%', 0.25),
  TaxRateOption('GST@3%', 3.0),
  TaxRateOption('IGST@3%', 3.0),
  TaxRateOption('GST@5%', 5.0),
  TaxRateOption('IGST@5%', 5.0),
  TaxRateOption('GST@12%', 12.0),
  TaxRateOption('IGST@12%', 12.0),
  TaxRateOption('GST@18%', 18.0),
  TaxRateOption('IGST@18%', 18.0),
  TaxRateOption('GST@28%', 28.0),
  TaxRateOption('IGST@28%', 28.0),
  TaxRateOption('GST@40%', 40.0),
  TaxRateOption('IGST@40%', 40.0),
];