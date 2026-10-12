import {
  Box,
  Card,
  CardContent,
  Skeleton,
  Stack,
  Typography,
} from '@mui/material'
export default function StatCard({ title, value, helper, icon, loading }) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Stack
          direction="row"
          sx={{ justifyContent: 'space-between', alignItems: 'center', mb: 2 }}
        >
          <Typography variant="body2" color="text.secondary" fontWeight={600}>
            {title}
          </Typography>
          <Box
            sx={{
              width: 34,
              height: 34,
              display: 'grid',
              placeItems: 'center',
              color: 'primary.main',
              bgcolor: 'action.selected',
              borderRadius: 2,
              '& svg': { fontSize: 19 },
            }}
          >
            {icon}
          </Box>
        </Stack>
        <Typography variant="h4" sx={{ fontSize: 30, mb: 0.75 }}>
          {loading ? <Skeleton width="60%" /> : value}
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {helper}
        </Typography>
      </CardContent>
    </Card>
  )
}
