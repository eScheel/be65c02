
const int data_bus = { 2, 3, 4, 5, 6, 7, 8, 9 };
const int read_write = 12;
const int chip_enable = 13;

void setup()
{
  for(size_t i=0; i<sizeof(data_bus); i++) {
    pinMode(data_bus[i], INPUT);  // Start off as input so as to not scramble the data bus.
  }
  pinMode(read_write, INPUT);
  pinMode(chip_enable, INPUT);
}

void loop()
{
  if(digitalRead(chip_enable) { return; } // Do nothing if chip is not active. Active Low.

  
}
