apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJek1ERXlPREl6TlRReE5sb1hEVE16TURFeU5USXpOVFF4Tmxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTjBOCkQzUmJYYTVxM0hQaWNsTVh4T2tRM3lxcWVWaGpqR3FHQVVCL2RGTlA4YVg1VU5yYnRmVk9KSDh1ME1yQ0c4YXQKdlMyWSsyQ2FMejBNSzUrSFRla0xiL0ExRWxWbGQvWFl6ekhVUVNzSUJ0Qm9NUWI0Y1BJRVg0czlPazRGZ0RzMwpOMTQyMjlhUGdBVzdubFJZNDlBelpGL21QdHNLckJvaU5hZi8zQWtHSkVSdWk4UlprcWhHVjd4OWhCNldZNzNEClhub05POFlwT0hjcjlNZEd3V3dHN3NQcWFWQ0xEaUhNaWZUWDdoNmZrR1ViZnhWZFJOZ2lEVGN3RmYwNUNWNU4KQ25wbmdMUlVQL2psTm55L3RpWER4MFk4RG5QSGt2c0tab3VTaGxBWGhMVjJKSno0VmlaTEpLNkllR3JqU0tVMApWZmZ6THlReWlwMWVBYWZFandzQ0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZNMEw0RVBXT3hFczB1SldSSjkwZlJIOC9Gc2FNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBTllQb0NDU1JUSDZRV2h6d29zYgpETjZQblhIK2ppT2J0eVZqamRYTERBeTg0eTBPUWlHV0FNRWp0MFlMUi8xRHNtd1hxSUlTYW94UklFekdVZ1FQCkY5Rk91SUFEQUZnSEhiT2lxV1JielNtSVpXQ2IzNm1YUkdSUWxzbmxKdTJaWC81bTdMZ052UGVybUsrUmdzazYKbUg1bkdLWUZEcDZLdlUrOENaYkF4L2VuWDZYM09hbWwrOFpqclR5clJVWWJ5c2RNa2tTR2RUYyszcUtUd0hoNQpvUWdnV0Zkbkt0TWFGRmlmQjY2RjRhNGlQOEFaSmJZS0k1UmpwdEFZVG43V0JTMmRLZ050MVBVVm9UT1NIYytjCmdxcHVsU2FacUExa3lMUGFvbjZTdGZ1V2RNc1MvdlRodXpYSkE4dndVNnF1M2ZxcFdpa0ZDUzJEQzN4czBYOG4KaXBNPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://8682402D3C6509EF91FD96AEB39DF1AB.gr7.us-east-1.eks.amazonaws.com
  name: arn:aws:eks:us-east-1:535849429554:cluster/target-cluster-target-00000001
contexts:
- context:
    cluster: arn:aws:eks:us-east-1:535849429554:cluster/target-cluster-target-00000001
    user: arn:aws:eks:us-east-1:535849429554:cluster/target-cluster-target-00000001
  name: arn:aws:eks:us-east-1:535849429554:cluster/target-cluster-target-00000001
current-context: arn:aws:eks:us-east-1:535849429554:cluster/target-cluster-target-00000001
kind: Config
preferences: {}
users:
- name: arn:aws:eks:us-east-1:535849429554:cluster/target-cluster-target-00000001
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --region
      - us-east-1
      - eks
      - get-token
      - --cluster-name
      - target-cluster-target-00000001
      command: aws
      env:
      - name: AWS_PROFILE
        value: proservlab