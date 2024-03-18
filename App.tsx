import React, {FC, useEffect, useState} from 'react';
import {StyleSheet, Text, View} from 'react-native';
import {
  PermissionStatus,
  checkNotifications,
  requestNotifications,
} from 'react-native-permissions';

const App: FC = (): any => {
  const [notificationStatus, setNotificationStatus] =
    useState<PermissionStatus>();
  useEffect(() => {
    checkNotifications().then(({status, settings}) => {
      setNotificationStatus(status);
      const statusIsGranted = status === 'granted';
      const isProvisional = settings.provisional;
      if (!statusIsGranted || (statusIsGranted && isProvisional)) {
        requestNotifications(['alert', 'sound', 'badge']).then(response => {
          setNotificationStatus(response.status);
        });
      }
    });
  }, []);

  return (
    <View style={styles.container}>
      <View>
        <Text style={styles.content}> permission: {notificationStatus} </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
    backgroundColor: 'black',
    marginTop: 40,
  },
  content: {
    color: 'white',
    fontSize: 40,
  },
});

export default App;
